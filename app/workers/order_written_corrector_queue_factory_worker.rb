class OrderWrittenCorrectorQueueFactoryWorker
  include Sidekiq::Worker

  def perform(order_id, locale = 'en')
    I18n.locale = locale
    order = Order::Written.find order_id
    date_iterator = DateTime.now
    create_queue = proc do |queue_name|
      build_method = "create_#{queue_name}_queue"
      queue = Order::Written::CorrectorsQueue.send build_method, order, date_iterator
      if queue.present?
        queue.lock_to <=DateTime.now ? queue.notify_about_create :
            Order::Written::CorrectorsQueue.delay_for(30.minutes).notify_queue(queue.id)
        date_iterator += 30.minutes
        true
      else
        false
      end
    end

    create_queue.call 'partner'
    create_queue.call 'senior'
    create_queue.call 'other_correctors'
  end
end