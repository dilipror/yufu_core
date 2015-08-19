class Order::HotelSerializer < ActiveModel::Serializer
  attributes :id, :greeted_at, :info
end
