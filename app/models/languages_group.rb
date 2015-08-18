class LanguagesGroup
  include Mongoid::Document

  embeds_many :verbal_prices,  class_name: 'Price::Verbal'
  embeds_many :written_prices, class_name: 'Price::Written'
  field :name

  has_many :languages

  accepts_nested_attributes_for :verbal_prices, :written_prices


  def verbal_price(level, currency = nil)
    price = verbal_prices.where(level: level).first
    price.nil? ? BigDecimal::INFINITY : price.value
  end

  def written_price(level, currency = nil)
    price = written_prices.where(level: level).first
    price.nil? ? BigDecimal::INFINITY : price.value
  end

  def verbal_cost(level, currency = nil)
    Price.without_markup verbal_price(level, currency)
  end

  def written_cost(level, currency = nil)
    Price.without_markup written_price(level, currency)
  end

end
