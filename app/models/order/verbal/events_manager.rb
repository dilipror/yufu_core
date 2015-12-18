class Order::Verbal::EventsManager
  include Mongoid::Document

  embedded_in :order_verbal, class_name: 'Order::Verbal'
  embeds_many :events, class_name: 'Order::Verbal::Event'

  after_initialize do
    if events.empty?
      events.new name: 'after_12'
      events.new name: 'after_24'
      events.new name: 'before_60'
      events.new name: 'before_48'
      events.new name: 'before_36'
      events.new name: 'before_24'
      events.new name: 'before_4'
    end
  end
end