class Order::Written::EventsManager
  include Mongoid::Document

  embedded_in :order_written, class_name: 'Order::Written'
  embeds_many :events, class_name: 'Order::Written::Event'

  after_initialize do
    if events.empty?
      events.new name: 'confirmation_order_in_30'
    end
  end
end