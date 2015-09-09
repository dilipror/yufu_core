require 'active_model/serializable'
module Yufu
  class TranslationProxy
    include ActiveModel::Serializable
    EXCEPTED_KEYS = /#{%w(mongoid.errors.messages. number. time. date.formats. support.array errors.messages. ransack.
                    flash. will_paginate. activemodel. views. admin.js. errors.format helpers. admin.loading
                    admin.misc.filter_date_format date.day_names date.abbr_day_names date.month_names abbr_month_names
                    date  ).join('|')}/

    MONGO_MODELS = %w(Language.name Order::Car.name City.name Order::Service.name Order::ServicesPack.name
                    Order::ServicesPack.short_description Order::ServicesPack.long_description Major.name
                    Order::Written::WrittenSubtype.name Order::Written::WrittenSubtype.description
                    Order::Written::WrittenType.name Order::Written::WrittenType.description
                    Gateway::PaymentGateway.title Gateway::PaymentGateway.description)


    attr_accessor :key, :locale, :translation

    @@keys = Set.new

    def initialize(key, translation, locale = 'en', version = nil, value = nil)
      @key = key
      @translation = translation
      @locale = locale
      @version = version
    end

    def value
      @translation.try(:value) || I18n.t(@key, locale: @locale)
    end

    def original
      I18n.t @key
    end

    def version_id
      @version.try :id
    end

    def read_attribute_for_serialization(key)
      send key
    end

    def self.all(version)
      result = []
      keys.each do |k|
        translation = version.translations.where(key: k).first
        result << TranslationProxy.new(k, translation, version.localization.name, version)
      end
      result
    end

    def self.only_updated(version)
      if version.english?
        version.translations.map do |t|
          TranslationProxy.new t.key, t, version.localization.name, version
        end
      else
        last_approved_version_number = version.localization.localization_versions
                                           .approved.where(:id.lte => version.id).desc(:id).first.try :version_number_id
        last_approved_version_number ||= 0
        available_version_numbers = Localization::VersionNumber.where(:number.gte => last_approved_version_number,
                                                                      :number.lte => version.version_number.number)
                                                               .distinct :id

        version_ids = Localization::Version.approved.where(:version_number_id.in => available_version_numbers)
                          .distinct :id
        Translation.where(:version_id.in => version_ids).distinct(:key).map do |k|
          TranslationProxy.new k, version.translations.where(key: k).first, version.localization.name, version
        end
      end
    end

    def self.update(key, value, version)
      if version.editable?
        t = version.translations.find_or_initialize_by key: key
        t.value = value
        t.save
      else
        false
      end
    end

    def self.to_csv(version, options = {})
      CSV.generate(options) do |csv|
        csv << ['key', I18n.locale, version.localization.name]
        all(version).each do |tr|
          csv << [tr.key, tr.original.to_s, tr.value.to_s]
        end
      end
    end

    def self.import(file_data, version)
      if file_data != ""
        text = Base64.decode64(file_data['data:text/csv;base64,'.length .. -1])
        arr_of_arrs = CSV.parse(text)

        arr_of_arrs.drop(1).each do |record|
          key = record[0]
          value = record[2]
          if value != I18n.t(key, locale: version.localization.name)
            tr = version.translations.find_or_initialize_by key: key
            tr.value = value
            tr.save!
          end
        end
        true
      end
    end

    def self.keys
      return @@keys unless @@keys.empty?
      TranslationProxy.reset_keys
    end

    def self.reset_keys
      @@keys = Set.new
      I18n.backend.backends.each do |back|
        if back.is_a? I18n::Backend::Simple
          back.send :init_translations
          I18n.backend.send(:translations).each do |locale, hash|
            hash.flatten_hash.each do |k, v|
              @@keys << k.to_s unless EXCEPTED_KEYS === k
            end
          end
        end
      end

      @@keys += Translation.distinct(:key).map(&:to_s)

      MONGO_MODELS.each do |temp|
        t = temp.split('.')
        klass = t[0]
        que = (klass.constantize).all.pluck(:id, t[1].parameterize.underscore.to_sym)
        # klass
        que.each do |k|
          key = klass.gsub('::', '_') + '.' + t[1] + '.' + k[0]
          @@keys << key.to_s
        end
      end
      @@keys
    end


  end
end