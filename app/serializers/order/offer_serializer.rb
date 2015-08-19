class Order::OfferSerializer < ActiveModel::Serializer
  attributes :id, :status, :is_confirmed
end
