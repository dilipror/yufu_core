module Order
  class GetOriginal
    include Mongoid::Document

    embedded_in :order_written, class_name: 'Order::Written'
    TYPES = ['post', 'urgent_letter', 'courier']

    field :name
    field :address
    field :index

  end
end