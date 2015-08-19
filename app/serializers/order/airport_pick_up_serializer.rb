class Order::AirportPickUpSerializer < ActiveModel::Serializer
  attributes :id, :need_car, :double_way, :flight_number, :airport_name, :arriving_date, :departure_city
end
