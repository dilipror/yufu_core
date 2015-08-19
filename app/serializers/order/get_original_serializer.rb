class Order::GetOriginalSerializer < ActiveModel::Serializer
  attributes :id, :name, :address, :index
end
