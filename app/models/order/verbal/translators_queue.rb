class Order::Verbal::TranslatorsQueue
  include Mongoid::Document
  include Notificable
  include Sidekiq

  field :lock_to, type: DateTime

  belongs_to :order_verbal, class_name: 'Order::Verbal'
  has_and_belongs_to_many :translators, class_name: 'Profile::Translator', inverse_of: :order_verbal_translators_queues

  scope :active, -> {where :lock_to.lte => DateTime.now}

  has_notification_about :create, observers: :translators, message: 'notifications.new_order',
                         mailer: -> (user, queue) { NotificationMailer.new_order_for_translator_16 user }

  # HARD CODE!!!!!!!!!! HABTM doesn't work
  after_create do
    translators.each {|t| t.order_verbal_translators_queues << self}
  end

  # Queue builders
  def self.create_agent_queue(order, lock_to = DateTime.now)
    return nil unless order.is_a? Order::Verbal
    agents = []
    order.agents.each do |agent|
      agents << agent.profile_translator if order.supported_by?(agent.profile_translator) &&
          agent.profile_translator.city_approves.where(with_surcharge: false, city: order.location).count > 0
    end

    if agents.empty?
      nil
    else
      Order::Verbal::TranslatorsQueue.create order_verbal: order, translators: agents, lock_to: lock_to
    end
  end

  def self.create_native_queue(order, lock_to = DateTime.now)
    return nil unless order.is_a?(Order::Verbal) && order.want_native_chinese
    translators = Profile::Translator.support_order(order).chinese.without_surcharge(order.location).to_a
    if translators.nil? || translators.empty?
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
      if order.language.senior.city_approves.where(with_surcharge: false, city: order.location).count > 0 && order.supported_by?(order.language.senior)
        Order::Verbal::TranslatorsQueue.create order_verbal: order, translators: [order.language.senior], lock_to: lock_to
      else
        nil
      end
    end
  end

  def self.create_without_surcharge_queue(order, lock_to = DateTime.now)
    return nil unless order.is_a?(Order::Verbal)
    blacklist = order.translators_queues.inject([]){|arr, q| arr + q.translator_ids}
    unless order.include_near_city
      translators = Profile::Translator.support_order(order).and(:id.nin => blacklist).without_surcharge(order.location)
      if translators.empty?
        nil
      else
        Order::Verbal::TranslatorsQueue.create order_verbal: order, translators: translators, lock_to: lock_to
      end
    else
      nil
    end
  end

  def self.create_with_surcharge_queue(order, lock_to = DateTime.now)
    return nil unless order.is_a?(Order::Verbal)
    blacklist = order.translators_queues.inject([]){|arr, q| arr + q.translator_ids}
    translators = Profile::Translator.support_order(order).and(:id.nin => blacklist)
    if translators.empty?
      nil
    else
      Order::Verbal::TranslatorsQueue.create order_verbal: order, translators: translators, lock_to: lock_to
    end
  end

end
