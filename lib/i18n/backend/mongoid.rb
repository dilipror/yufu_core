module I18n
  module Backend
    class Mongoid
      include Base, Flatten

      def available_locales
        Localization.all.distinct :name
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