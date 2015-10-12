class Order::Written::CorrectorsQueue
  include Mongoid::Document
  include Notificable
  include Sidekiq

  field :lock_to, type: DateTime

  belongs_to :order_written, class_name: 'Order::Written'
  has_and_belongs_to_many :translators, class_name: 'Profile::Translator',
                          inverse_of: :order_written_translators_queues

  scope :active, -> {where :lock_to.lte => DateTime.now}

  # HARD CODE!!!!!!!!!! HABTM doesn't work
  after_create do
    translators.each {|t| t.order_written_correctors_queues << self}
  end

  has_notification_about :create, observers: :translators, message: 'notifications.new_order',
                         mailer: -> (user, queue) { NotificationMailer.new_order_for_translator(user).deliver }

  def self.notify_queue(queue_id)
    queue = Order::Written::CorrectorsQueue.find queue_id
    queue.notify_about_create
  end

  # Queue builders
  def self.create_partner_queue(order, lock_to = DateTime.now)
    return nil unless order.is_a? Order::Written
    return nil unless order.referral_link.nil? || order.banner.nil?
    partner = []
    if order.referral_link.present?
      partner << order.referral_link.user.profile_translator if order.referral_link.user.profile_translator.support_correcting_written_order?(order)
    end
    if order.banner.present?
      partner << order.banner.user.profile_translator if order.banner.user.profile_translator.support_correcting_written_order?(order)
    end
    if partner.empty?
      nil
    else
      queue_builder order, partner, lock_to
    end
  end

  def self.create_senior_queue(order, lock_to = DateTime.now)
    return nil unless order.is_a? Order::Written
    return nil unless (order.original_language.senior.present? || order.translation_language.senior.present?)
    seniors = []
    seniors << order.original_language.senior if order.original_language.senior.present? &&
        order.original_language.senior.support_correcting_written_order?(order)
    seniors << order.translation_language.senior if order.translation_language.senior.present? &&
        order.translation_language.senior.support_correcting_written_order?(order)

    if seniors.empty?
      nil
    else
      queue_builder order, seniors, lock_to
    end
  end

  def self.create_other_correctors_queue(order, lock_to = DateTime.now)
    return nil unless order.is_a? Order::Written
    blacklist = order.translators_queues.inject([]){|arr, q| arr + q.translator_ids}
    translators = Profile::Translator.support_correcting_written_order(order).and(:id.nin => blacklist)
    if translators.empty?
      nil
    else
      queue_builder order, translators, lock_to
    end
  end

  def self.queue_builder(order, translators, lock_to)
    create order_written: order, translators: translators, lock_to: lock_to
  end
end
