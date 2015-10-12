class CloseUnpaidJob < ActiveJob::Base
  queue_as :default

  def perform(order_id)
    if state == 'paying' || state == 'new'
      order = Order::Base.find order_id
      klass = "::#{order._type}::RejectService"
      service = klass.constantize.new(order)
      service.reject_order :yufu
    end
  end
end
