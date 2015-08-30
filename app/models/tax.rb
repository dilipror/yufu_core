class Tax
  include Mongoid::Document

  field :name, localize: true
  field :tax
  field :original_is_needed, type: Boolean

  has_and_belongs_to_many :countries
  has_and_belongs_to_many :payment_gateways, class_name: 'Gateway::PaymentGateway'
  has_and_belongs_to_many :invoices

  belongs_to :company
end