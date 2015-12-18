class OrderWrittenWorkflowWorker < ActiveJob::Base
  queue_as :default

  def perform(id, stamp)
    order = Order::Written.find id
    event = order.events_manager.try(:events).try(:where, name: stamp)
    if event.present?
      event.run unless event.is_complete
    else
      Order::Written::EventsService.new(order).send stamp
    end
  end
end