module AttributesDelegator
  extend ActiveSupport::Concern
  module ClassMethods

    def delegate_attributes(*methods)
      options = methods.pop
      unless options.is_a?(Hash) && to = options[:to]
        raise ArgumentError, 'Delegation needs a target. Supply an options hash with a :to key as the last argument (e.g. delegate :hello, to: :greeter).'
      end
      to = to.to_s
      to = 'self.class' if to == 'class'
      methods.each do |method|
        module_eval("def #{method}();_ = #{to};return read_attribute(:#{method}).present? ? read_attribute(:#{method}) : _.try(:subject).try(:owner).try(:#{method});end;")
      end
    end
  end
end