module Order
  class AirportPickUp
    include Mongoid::Document
    include MultiParameterAttributes

    field :need_car,       type: Mongoid::Boolean
    field :double_way,     type: Mongoid::Boolean
    field :flight_number,  type: String
    field :airport_name,   type: String
    field :arriving_date,  type: DateTime
    field :departure_city, type: String

    embedded_in :order_base
  end
end
