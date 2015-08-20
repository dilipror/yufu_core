module I18n
  module Backend
    class Mongoid
      include Base, Flatten

      def initialized?; true; end

      def available_locales
        Localization.all.distinct :name
      end

      def init_translations; end

      def translations
        trans = {}
        Translation.not_model_localizers.each do |t|
          trans_pointer = trans
          locale = t.version.localization.name
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
        approved_version_ids = Localization::Version.approved.where(localization: localization).distinct :id
        Translation.where(key: key, :version_id.in => approved_version_ids).desc(:version_id).first.try(:value)
      end
    end
  end
end