class CloseVerbalJob < ActiveJob::Base
  queue_as :default

  def perform(order_id, method)
    order = Order::Verbal.find order_id
    order.send method
  end
end
