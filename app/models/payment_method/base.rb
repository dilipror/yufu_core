module PaymentMethod
  class Base
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    field :is_active, type: Mongoid::Boolean, default: false

    embedded_in :billing
    embeds_one :billing_address, class_name: 'PaymentMethod::BillingAddress', cascade_callbacks: true

    accepts_nested_attributes_for :billing_address

    def owner?(user)
      return false if billing.user.nil?
      user == billing.user
    end

  end
end