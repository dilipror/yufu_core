class OrderWorkflowWorker < ActiveJob::Base
  queue_as :default

  def perform(id, stamp)
    order = Order::Verbal.find id
    event = order.events_manager.try(:events).try(:where, name: stamp)
    if event.present?
      event.run unless event.is_complete
    else
      Order::Verbal::EventsService.new(order).send stamp
    end
  end
end