class ActivateVerbalTranslationQueueJob < ActiveJob::Base
  queue_as :default

  def perform(queue_id)
    queue = Order::Verbal::TranslatorsQueue.find queue_id
    queue.notify_about_create
  end
end