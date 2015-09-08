class Company
  include Mongoid::Document
  
  field :name, localize: true
  field :tooltip, localize: true
  field :support_copy_invoice, type: Boolean

  belongs_to :currency

  has_and_belongs_to_many :payment_gateways, class_name: 'Gateway::PaymentGateway'
end