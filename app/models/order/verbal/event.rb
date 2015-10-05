class Order::Verbal::Event
  include Mongoid::Document

  field :name, type: String
  field :is_complete, type: Mongoid::Boolean, default: false

  embedded_in :events_manager, class_name: 'Order::Verbal::EventsManager'

  def run
    unless is_complete
      Order::Verbal::EventsService.new(events_manager.order_verbal).send name
    end
    update is_complete: true
  end
end