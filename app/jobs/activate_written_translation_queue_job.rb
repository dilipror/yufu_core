class ActivateWrittenTranslationQueueJob < ActiveJob::Base
  queue_as :default

  def perform(queue_id)
    queue = Order::Written::TranslatorsQueue.find queue_id
    queue.notify_about_create
  end
end