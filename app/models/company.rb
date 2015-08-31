class Company
  include Mongoid::Document
  
  field :name, localize: true
  field :tooltip, localize: true
  field :support_copy_invoice, type: Boolean

  belongs_to :currency
end