class Order::CarSerializer < ActiveModel::Serializer
  attributes :id, :name, :cost
end
