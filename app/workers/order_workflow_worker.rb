class OrderWorkflowWorker
  include Sidekiq::Worker

  def perform(id, stamp)
    order = Order::Verbal.find id
    Order::Verbal::EventsService.new(order).send stamp
  end
end