class OrderWorkflowWorker < ActiveJob::Base
  queue_as :default

  def perform(id, stamp)
    Order::Verbal::EventsService.new(order).send stamp
  end
end