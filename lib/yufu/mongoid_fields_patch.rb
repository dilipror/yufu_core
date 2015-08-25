module Mongoid
  module Fields
    module ClassMethods
      def create_field_getter(name, meth, field)
        generated_methods.module_eval do
          re_define_method(meth) do
            raw = read_attribute(name)
            if lazy_settable?(field, raw)
              write_attribute(name, field.eval_default(self))
            else
              if field.is_a? Mongoid::Fields::Localized
                value = field.demongoize(raw, self)
              else
                value = field.demongoize(raw)
              end
              attribute_will_change!(name) if value.resizable?
              value
            end
          end
        end
      end
    end

  end
end