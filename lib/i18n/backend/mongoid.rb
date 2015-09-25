module I18n
  module Backend
    class Mongoid
      include Base, Flatten

      def initialized?; true; end

      def available_locales
        Localization.all.distinct :name
      end

      def init_translations; end

      def translations(version = nil)
        trans = {}

        if version.nil?
          query = Translation.active
          locale = nil
        else
          query = Translation.all_translation_by_version(version)
          locale = version.localization.name
        end

        query.each do |t|
          trans_pointer = trans
          locale ||= t.version.localization.name
          k = "#{locale}.#{t.key.to_s}"
          key_array = k.split(".")
          last_key = key_array.delete_at(key_array.length - 1)
          key_array.each do |current|
            unless trans_pointer.has_key?(current.to_sym)
              trans_pointer[current.to_sym] = {}
            end
            trans_pointer = trans_pointer[current.to_sym]
          end
          begin
            key = k.gsub "#{locale}.", ''
            trans_pointer[last_key.to_sym] = I18n.t key, locale: locale
          rescue => e
            puts 'Fail of get all translations'
            puts e.message
            puts e.backtrace.join("\n")
            puts "last key is #{last_key}"
            puts "key is #{k}"
            puts "End fail"
          end

        end
        trans
      end

      protected
      def lookup(locale, key, scope = [], options = {})
        localization = Localization.where(name: locale).first
        key = normalize_flat_keys(locale, key, scope, options[:separator])
        return nil if localization.nil?

        from_models = try_from_models(key, locale)
        return from_models if from_models.present?

        value = nil

        if I18n.config.try(:locale_version).present?
          value = Translation.where(key: key, version_id: I18n.config.locale_version.id).first.try(:value)
        end

        if value.nil?
          approved_version_ids = Localization::Version.approved.where(localization: localization).distinct :id
          value = Translation.where(key: key, :version_id.in => approved_version_ids).desc(:version_id).first.try(:value)
        end
        value
      end

      def try_from_models(key, locale)
        key = key.gsub('_', '::')
        decoded_key = key.split('.')
        klass = decoded_key[0]
        field = decoded_key[1].gsub('::', '_')
        id    = decoded_key[2]
        if Object.const_defined?(klass)
          klass.constantize.where(id: id).first.try field
        else
          nil
        end
      rescue
        nil

      end
    end
  end
end