class Invoice::Item
  include Mongoid::Document
  include Monetizeable
  include Mongoid::Autoinc
  extend Enumerize

  field :description, type: String
  field :cost, type: BigDecimal
  field :number, type: Integer

  increments :number

  validates_presence_of :description, :cost

  monetize :cost

  embedded_in :invoice
end
