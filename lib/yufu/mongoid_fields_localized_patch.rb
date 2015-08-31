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
    end
  end
end
