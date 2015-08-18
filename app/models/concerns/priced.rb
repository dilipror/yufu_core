module Priced
  extend ActiveSupport::Concern

  def price(currency = nil)
    (Currency.exchange original_price, currency).to_f
  end

  def original_cost
    Price.without_markup original_price
  end

  def cost(currency = nil)
    (Currency.exchange original_cost, currency).to_f
  end
end