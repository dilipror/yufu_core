class Order::CarRentSerializer < ActiveModel::Serializer
  attributes :id, :duration, :cost
  has_one :car
end
