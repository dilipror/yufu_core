class RemindAboutCloseUnpaidJob < ActiveJob::Base
  queue_as :default

  def perform(order_id)
    order = Order::Base.find order_id
    if order.new? || order.paying?
      order.notify_about_remind_billing_info_2
    end
  end
end
