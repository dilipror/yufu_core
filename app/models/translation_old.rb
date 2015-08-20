class TranslationOld
  include ActiveModel::Serializable

  EXCEPTED_KEYS = /#{%w(mongoid.errors.messages. number. time. date.formats. support.array errors.messages. ransack.
                    flash. will_paginate. activemodel. views. admin.js. errors.format helpers. admin.loading
                     admin.misc.filter_date_format ).join('|')}/

  MONGO_MODELS = %w(Language.name Order::Car.name City.name Order::Service.name Order::ServicesPack.name
                    Order::ServicesPack.short_description Order::ServicesPack.long_description Major.name
                    Order::Written::WrittenSubtype.name Order::Written::WrittenSubtype.description
                    Order::Written::WrittenType.name Order::Written::WrittenType.description)

  @@keys = Set.new
  attr_accessor :key, :original, :value, :storage, :locale

  def initialize(key, locale, storage, org, vl)
    if storage == 'redis'
      @key = key
      @original = I18n.t(key)
      if vl != ''
        @value = vl
      else
        @value = I18n.t(key, locale: locale, default: '')
      end

    end
    if storage == 'mongo'
      @key = key
      if org == nil
        org = key
      end
      @original = org
      @value = vl
    end
    @storage = storage
    @locale = locale
  end

  def read_attribute_for_serialization(key)
    send key


  end

  def self.all(target_locale)
    result = []
    # temp = MONGO_MODELS[0]
    MONGO_MODELS.each do |temp|
      t = temp.split('.')
      klass = t[0]
      que = (klass.constantize).all.pluck(:id, t[1].parameterize.underscore.to_sym)
      # klass
      que.each do |k|
        key = klass.gsub('::', '_') + '.' + t[1] + '.' + k[0]

        result << TranslationOld.new(key, target_locale, 'mongo', k[1][:en], k[1][target_locale])
      end

    end
    keys.each {|k| result << TranslationOld.new(k, target_locale, 'redis', '', '')}
    result

  end


  def save()
    if storage == 'mongo'
      tmp = key.split('.')
      # target_locale = locale.parameterize.underscore.to_sym
      target_locale = locale
      klass = tmp[0].gsub('_', '::')
      klass = klass.constantize
      field = tmp[1].parameterize.underscore.to_sym
      id = tmp[2]

      que = klass.find_by(id: id)

      I18n.locale = target_locale
      que[field] = value
      que.save
    end
    if storage == 'redis'
        I18n.backend.store_translations(locale, {key => value}, escape: false)
        # I18nJsExportWorker.perform_async
    end
  end

  def self.keys
    return @@keys unless @@keys.empty?
    TranslationOld.reset_keys
  end

  def self.reset_keys
    @@keys = Set.new
    I18n.backend.send :init_translations
    I18n.backend.send(:translations).each do |locale, hash|
      hash.flatten_hash.each do |k, v|
        @@keys << k unless EXCEPTED_KEYS === k
      end
    end
    @@keys =  @@keys.to_a.sort {|x, y| x.to_s <=> y.to_s}
  end

  def self.to_csv(target_locale, options = {})
    CSV.generate(options) do |csv|
      csv << ['key', I18n.locale, target_locale, 'storage']
      all(target_locale).each do |tr|
        csv << [tr.key, tr.original, tr.value, tr.storage]

      end
    end
  end


  def self.import(file_data, current_user = nil)
    if file_data != ""
      text = Base64.decode64(file_data['data:text/csv;base64,'.length .. -1])
      arr_of_arrs = CSV.parse(text)
      target_locale = arr_of_arrs[0][2]

      if current_user != nil
        if current_user.localizations.where(name: target_locale).count == 1
          if target_locale.present?
            arr_of_arrs.drop(1).each do |record|
              tmp = TranslationOld.new(record[0], target_locale, record[3], record[1], record[2])
              # Translation.new(params[:id], target_locale, params[:translation][:storage], params[:translation][:original],
              #                 params[:translation][:value])
              tmp.save
            end
          true
          end
        end
      end
    end
  end
end