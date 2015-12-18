class Company
  include Mongoid::Document
  
  field :name, localize: true
  field :address, localize: true
  field :registration_number, localize: true
  field :tooltip, localize: true
  field :bank_name, localize: true
  field :bank_account_number, localize: true
  field :bank_swift, localize: true
  field :bank_address, localize: true
  field :email, localize: true
  field :support_copy_invoice, type: Boolean

  belongs_to :currency

  has_and_belongs_to_many :payment_gateways, class_name: 'Gateway::PaymentGateway'
end