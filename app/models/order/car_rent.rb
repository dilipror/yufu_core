module Order
  # DEPRECATED
  class CarRent
    include Mongoid::Document
    include MultiParameterAttributes

    field :duration, type: Integer, default: 0
    belongs_to :car, class_name: 'Order::Car'

    embedded_in :order_base

    # validates_presence_of :car

    def cost
      unless car.nil?
        return 0 if car.cost.nil?
        car.cost * duration
      end
    end
  end
end