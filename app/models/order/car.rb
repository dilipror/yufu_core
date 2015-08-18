module Order
  # DEPRECATED
  class Car
    include Mongoid::Document

    field :name, localize: true
    field :cost, type: Money, default: Money.new(0, 'CNY')

    def price
      Price.exchange_currency cost
    end

  end
end