class OrderWorkflowWorker < ActiveJob::Base
  queue_as :default

  def perform(id, stamp)
    order = Order::Verbal.find id
    Order::Verbal::EventsService.new(order).send stamp
  end
end