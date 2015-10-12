class Order::Written::Event
  include Mongoid::Document

  field :name, type: String
  field :is_complete, type: Mongoid::Boolean, default: false

  embedded_in :events_manager, class_name: 'Order::Written::EventsManager'

  def run
    Order::Written::EventsService.new(events_manager.order_written).send name
    self.is_complete = true
    events_manager.save!
  end
end