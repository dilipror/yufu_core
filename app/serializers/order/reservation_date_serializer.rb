class Order::ReservationDateSerializer < ActiveModel::Serializer
  attributes :id, :date, :hours, :price, :is_confirmed
end
