class OrderWorkflowWorker
  include Sidekiq::Worker

  def perform(id, stamp)
    order = Order::Verbal.find id
    order.send stamp
  end
end