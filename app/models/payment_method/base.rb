module PaymentMethod
  class Base
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    field :is_active, type: Mongoid::Boolean, default: false

    belongs_to :currency

    embedded_in :billing
    embeds_one :billing_address, class_name: 'PaymentMethod::BillingAddress', cascade_callbacks: true

    accepts_nested_attributes_for :billing_address

    validates_presence_of :currency_id

    def owner?(user)
      return false if billing.user.nil?
      user == billing.user
    end

    def available_currencies_ids

    end

  end
end