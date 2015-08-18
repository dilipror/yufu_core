class Order::Written::WrittenSubtype
  include Mongoid::Document

  field :name,        localize: true
  field :description, localize: true

  belongs_to :type, class_name: 'Order::Written::WrittenType'

  # has_many :orders, class_name: 'Order::Written'
end