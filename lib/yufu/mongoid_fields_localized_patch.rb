module Mongoid
  module Fields
    class Localized
      def demongoize(object, document = nil)
        if object
          type.demongoize(lookup_with_documents(object, document))
        end
      end

      private
      def lookup_with_documents(object, document = nil)
        value = nil
        if I18n.config.locale_version.present?
          value = Translation.where(key: "#{self.options[:klass].to_s.gsub('::', '_')}.#{self.name}.#{document.id}",
                                    version_id: I18n.config.locale_version.id).first.try(:value)
        end
        value || lookup(object)
      end

      def lookup(object)
        locale = ::I18n.locale
        if ::I18n.respond_to?(:fallbacks)
          object[::I18n.fallbacks[locale].map(&:to_s).find{ |loc| object.has_key?(loc) && !object[loc].blank? }]
        else
          object[locale.to_s]
        end
      end
    end
  end
end
