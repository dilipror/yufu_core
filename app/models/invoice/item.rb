class Invoice::Item
  include Mongoid::Document
  include Monetizeable
  extend Enumerize

  field :description, type: String
  field :cost, type: BigDecimal
  auto_increment :number


  validates_presence_of :description, :cost

  monetize :cost

  embedded_in :invoice
end
