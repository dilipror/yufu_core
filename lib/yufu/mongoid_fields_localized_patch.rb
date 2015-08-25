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
        if I18n.config.locale_version.present?
          I18n.t "#{self.options[:klass].to_s.gsub('::', '_')}.#{self.name}.#{document.id}", default: lookup(object)
        else
          lookup(object)
        end
      end
    end
  end
end
