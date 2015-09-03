class Billing
  include Mongoid::Document

  field :is_active, type: Mongoid::Boolean, default: true
  field :pay_way

  embeds_one :payment_method, class_name: 'PaymentMethod::Base', cascade_callbacks: true

  accepts_nested_attributes_for :payment_method, allow_destroy: true

  belongs_to :user
end
