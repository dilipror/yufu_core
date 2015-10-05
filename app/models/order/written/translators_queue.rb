class Order::Written::TranslatorsQueue
  include Mongoid::Document
  include Notificable
  include Sidekiq

  field :lock_to, type: DateTime

  belongs_to :order_written, class_name: 'Order::Written'
  has_and_belongs_to_many :translators, class_name: 'Profile::Translator',
                          inverse_of: :order_written_translators_queues

  scope :active, -> {where :lock_to.lte => DateTime.now}

  has_notification_about :create, observers: :translators, message: 'notifications.new_order',
                         mailer: -> (user, queue) { NotificationMailer.new_order_for_translator(user).deliver }

  def self.notify_queue(queue_id)
    queue = Order::Written::TranslatorsQueue.find queue_id
    queue.notify_about_create
  end

  # Queue builders
  def self.create_partner_queue(order, lock_to = DateTime.now)
    return nil unless order.is_a? Order::Written
    return nil if order.referral_link.nil?
    partner = []
    partner << order.referral_link.user.profile_translator if Order::Written.available_for(order.referral_link.user.profile_translator)
    if partner.empty?
      nil
    else
      Order::Written::TranslatorsQueue.create order_written: order, translators: partner, lock_to: lock_to
    end
  end

  def self.create_chinese_translators_queue(order, lock_to = DateTime.now)
    return nil unless order.is_a? Order::Written
    chinese_translators = []
    chinese_translators << Profile::Translator.chinese.support_written_order(order)
    if chinese_translators.empty?
      nil
    else
      Order::Written::TranslatorsQueue.create order_written: order, translators: chinese_translators, lock_to: lock_to
    end
  end

  def self.create_senior_queue(order, lock_to = DateTime.now)
    return nil unless order.is_a? Order::Written

  end

  def self.create_other_translators_queue(order, lock_to = DateTime.now)
    return nil unless order.is_a? Order::Written

  end
end
