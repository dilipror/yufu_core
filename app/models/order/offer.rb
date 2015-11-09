module Order
  class Offer
    include Mongoid::Document
    include Notificable
    include Mongoid::Timestamps::Created

    STATUSES = %w(primary secondary)

    field :state

    belongs_to :translator, class_name: 'Profile::Translator'
    belongs_to :order,      class_name: 'Order::Verbal'

    validates_presence_of :order

    validate :only_one_new_offer, unless: ->(offer) {offer.can_reconfirm?}

    after_create :notify_about_become_main_int_17, if: :primary?
    after_create :notify_about_become_back_up_int_18, if: :back_up?
    after_create :notify_about_order_details_4
    after_create :confirm_after_create
    after_create :order_transition

    has_notification_about :become_main_int_17,
                           message: 'notifications.become_main_int_17',
                           observers: :translator,
                           mailer: (-> (user, offer) do
                             NotificationMailer.become_main_int_17 user.id.to_s
                           end),
                           sms: -> (user, offer) do
                             Yufu::SmsNotification.instance.become_main_int_17 user
                           end

    has_notification_about :become_back_up_int_18,
                           message: 'notifications.become_back_up_int_18',
                           observers: :translator,
                           mailer: (-> (user, offer) do
                             NotificationMailer.become_back_up_int_18 user.id.to_s
                           end),
                           sms: -> (user, offer) do
                             Yufu::SmsNotification.instance.become_back_up_int_18 user
                           end

    has_notification_about :order_details_4,
                           message: 'notifications.order_details_4',
                           observers: -> (offer){ offer.order.owner.user },
                           mailer: -> (user, offer) do
                             NotificationMailer.order_details_4 user.id.to_s, offer.id.to_s
                           end


    has_notification_about :re_confirm_main_19,
                           message: 'notifications.re_confirm_main_19',
                           observers: :translator,
                           mailer: (-> (user, offer) do
                             NotificationMailer.re_confirm_main_19 user.id.to_s
                           end),
                           sms: -> (user, offer) do
                             Yufu::SmsNotification.instance.re_confirm_main_19 user
                           end


    has_notification_about :re_confirm_back_up_20,
                           message: 'notifications.re_confirm_back_up_20',
                           observers: :translator,
                           mailer: (-> (user, offer) do
                             NotificationMailer.re_confirm_back_up_20 user.id.to_s
                           end),
                           sms: -> (user, offer) do
                             Yufu::SmsNotification.instance.re_confirm_back_up_20 user
                           end

    has_notification_about :re_confirmed_translator_21,
                           message: 'notifications.re_confirmed_translator_21',
                           observers: :translator,
                           mailer: (-> (user, offer) do
                             NotificationMailer.re_confirmed_translator_21 user.id.to_s
                           end),
                           sms: -> (user, offer) do
                             Yufu::SmsNotification.instance.re_confirmed_translator_21 user
                           end

    has_notification_about :re_confirmed_client_6,
                           message: 'notifications.re_confirmed_client_6',
                           observers: -> (offer){ offer.order.owner.user },
                           mailer: -> (user, offer) do
                             NotificationMailer.re_confirmed_client_6 user.id.to_s, offer.id.to_s
                           end

    scope :state_new, -> {where state: :new}
    scope :new_or_confirmed, -> {where :state.in => [:new, :confirmed]}
    scope :confirmed, -> {where state: :confirmed}
    scope :rejected, -> {where state: :rejected}

    state_machine initial: :new do
      state :rejected
      state :confirmed

      event :reject do
        transition new: :rejected
      end

      event :confirm do
        transition new: :confirmed
      end

      before_transition new: :confirmed do |offer|
        can_reconfirm = offer.can_reconfirm?
        if can_reconfirm
          offer.order.process
          offer.notify_about_re_confirmed_translator_21
          if offer.translator != offer.order.offers.first.translator && offer.translator != offer.order.offers[1].translator
            offer.notify_about_re_confirmed_client_6
          end
        end
        can_reconfirm
      end

      before_transition new: :rejected do |offer|
        offer.translator.update is_banned: true
        if offer.primary?
          ban_time = 3.months
        else
          ban_time = 3.hours
        end
        offer.order.paid_ago?(12.hours) ? offer.order.reject_confirm_before_12 : offer.order.reject_confirm_after_12
        BanExpireWorker.set(wait: ban_time).perform_later offer.translator.id.to_s
      end
    end

    def can_reconfirm?
      case
        when order.reconfirm_delay?
          return true
        when order.main_reconfirm_delay?
          return false unless (primary? || back_up?)
        when order.need_reconfirm?
          return false unless primary?
        else
          return false
      end
      true
    end

    def can_be_primary?
      order.can_send_primary_offer?
    end

    def can_be_secondary?
      order.can_send_secondary_offer?
    end

    def primary?
      self == order.offers.where(state: 'new').first
    end

    def back_up?
      self == order.offers.where(state: 'new')[1]
    end

    private

    def order_transition
      order.confirm
    end

    def only_one_new_offer
      if order.offers.where(translator: translator, state: 'new').count > 1
        errors.add :translator_id, 'is_already_taken'
      end
    end

    def process_order
      order.process
    end

    def confirm_after_create
      if order.reconfirm_delay?
        confirm
      end
    end

    def order_has_primary_offer?
      order.offers.where(status: 'primary').count > 0
    end

  end
end
