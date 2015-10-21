class CloseUnpaidJob < ActiveJob::Base
  queue_as :default

  def perform(order_id)
    order = Order::Base.find order_id
    if order.state == 'paying' || order.state == 'new'
      order.notify_about_cancel_not_paid_3
      klass = "::#{order._type}::RejectService"
      service = klass.constantize.new(order)
      service.reject_order :yufu
    end
  end
end
