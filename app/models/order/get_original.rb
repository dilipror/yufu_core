module Order
  class GetOriginal
    include Mongoid::Document

    embedded_in :order_written, class_name: 'Order::Written'
    TYPES = ['post', 'urgent_letter', 'courier']

    field :send_type
    field :name
    field :address
    field :index

    validates_presence_of :name, :address, :index, if: -> {send_type.present? && order_written.step == 2}

  end
end