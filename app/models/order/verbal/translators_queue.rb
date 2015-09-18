class Order::Verbal::TranslatorsQueue
  include Mongoid::Document
  include Notificable
  include Sidekiq

  field :lock_to, type: DateTime

  belongs_to :order_verbal, class_name: 'Order::Verbal'
  has_and_belongs_to_many :translators, class_name: 'Profile::Translator', inverse_of: :order_verbal_translators_queues

  scope :active, -> {where :lock_to.lte => DateTime.now}

  has_notification_about :create, observers: :translators, message: 'notifications.new_order',
                         mailer: -> (user, queue) { NotificationMailer.new_order_for_translator(user).deliver }

  def self.notify_queue(queue_id)
    queue = Order::Verbal::TranslatorsQueue.find queue_id
    queue.notify_about_create
  end


  # Queue builders
  def self.create_agent_queue(order, lock_to = DateTime.now)
    return nil unless order.is_a? Order::Verbal
    agents = []
    order.agents.each do |agent|
      agents << agent.profile_translator if order.supported_by?(agent.profile_translator)
    end

    if agents.empty?
      nil
    else
      Order::Verbal::TranslatorsQueue.create order_verbal: order, translators: agents, lock_to: lock_to
    end
  end

  def self.create_native_queue(order, lock_to = DateTime.now)
    return nil unless order.is_a?(Order::Verbal) && order.want_native_chinese
    translators = Profile::Translator.support_order(order).chinese
    if translators.empty?
      nil
    else
      Order::Verbal::TranslatorsQueue.create order_verbal: order, translators: translators, lock_to: lock_to
    end
  end

  def self.create_senior_queue(order, lock_to = DateTime.now)
    return nil unless order.is_a?(Order::Verbal)
    if order.language.try(:senior).nil?
      nil
    else
      Order::Verbal::TranslatorsQueue.create order_verbal: order, translators: [order.language.senior], lock_to: lock_to
    end
  end

  def self.create_last_queue(order, lock_to = DateTime.now)
    blacklist = order.translators_queues.inject([]){|arr, q| arr + q.translator_ids}
    translators = Profile::Translator.support_order(order).and(:id.nin => blacklist)
    if translators.empty?
      nil
    else
      Order::Verbal::TranslatorsQueue.create order_verbal: order, translators: translators, lock_to: lock_to
    end
  end
end
