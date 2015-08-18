# It is fix for next bug:
# When I try to update an object with required localized field through rails_admin
# and the object has blank value for some locale, I have see an error/

module BlankLocalizedFields
  extend ActiveSupport::Concern

  module ClassMethods
    def clear_localized(*fields)
      fields.each do |field|
        if respond_to? field
          self.class_eval do
            before_validation do
              val = self.read_attribute(field)
              val.each_pair do |k, v|
                if I18n.locale != k
                  val.delete k if v.blank?
                end
              end
              true
            end
          end
        end
      end
    end
  end
end