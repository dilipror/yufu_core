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
    # validates_inclusion_of :status, in: STATUSES
    # validates_inclusion_of :status, in: %w(secondary), on: :create, unless: :can_be_primary?
    # validates_inclusion_of :status, in: %w(primary), on: :create, unless: :can_be_secondary?
    validate :only_one_new_offer, unless: ->(offer) {offer.order.will_begin_less_than?(36.hours)}
    validate :translator_is_not_banned, unless: :persisted?
    # validates_uniqueness_of :translator, scope: :order_id, unless: ->(offer) {offer.order.will_begin_less_than?(36.hours)}

    after_create :notify_about_become_main_int, if: :primary?
    after_create :notify_about_become_back_up_int, if: :back_up?
    after_create :notify_about_for_client
    after_create :confirm_after_create

    has_notification_about :become_main_int,
                           message: 'notifications.become_main_int',
                           observers: :translator,
                           mailer: (-> (user, offer) do
                             NotificationMailer.become_main_int(user).deliver
                           end),
                           sms: -> (user, offer) do
                             Yufu::SmsNotification.instance.become_main_int user
                           end

    has_notification_about :become_back_up_int,
                           message: 'notifications.become_main_int',
                           observers: :translator,
                           mailer: (-> (user, offer) do
                             NotificationMailer.become_back_up_int(user).deliver
                           end),
                           sms: -> (user, offer) do
                             Yufu::SmsNotification.instance.become_back_up_int user
                           end

    has_notification_about :for_client,
                           message: 'notifications.for_client',
                           observers: -> (offer){ offer.order.owner.user },
                           mailer: -> (user, offer) do
                             NotificationMailer.for_client(user, offer).deliver
                           end

    # has_notification_about :confirm_for_translator,
    #                        observers: :translator,
    #                        message: -> (offer) {"notifications.offers.confirm_#{offer.status}_offer_for_translator"},
    #                        mailer: -> (user, offer) do
    #                          if offer.primary?
    #                            NotificationMailer.primary_offer_confirmed offer.translator.user
    #                          else
    #                            NotificationMailer.secondary_offer_confirmed offer.translator.user
    #                          end
    #                        end,
    #                       sms: -> (user, offer) do
    #                         Yufu::SmsNotification.instance.offer_confirmed_for_translator(user)
    #                       end
    # has_notification_about :confirm_for_client,
    #                        observers: -> (offer){ offer.order.owner.user },
    #                        message: -> (offer) {"notifications.offers.confirm_#{offer.status}_offer_for_client"},
    #                        mailer: ->(user, offer) do
    #                          if offer.primary?
    #                            NotificationMailer.primary_offer_confirmed_for_client user, offer
    #                          else
    #                            NotificationMailer.secondary_offer_confirmed_for_client user, offer
    #                          end
    #                        end

    has_notification_about :re_confirm_main,
                           message: 'notifications.re_confirm',
                           observers: :translator,
                           mailer: (-> (user, offer) do
                             NotificationMailer.re_confirm_main(user).deliver
                           end),
                           sms: -> (user, offer) do
                             Yufu::SmsNotification.instance.re_confirm_main user
                           end


    has_notification_about :re_confirm_back_up,
                           message: 'notifications.re_confirm',
                           observers: :translator,
                           mailer: (-> (user, offer) do
                             NotificationMailer.re_confirm_back_up(user).deliver
                           end),
                           sms: -> (user, offer) do
                             Yufu::SmsNotification.instance.re_confirm_back_up user
                           end

    has_notification_about :re_confirmed_translator,
                           message: 'notifications.re_confirmed_translator',
                           observers: :translator,
                           mailer: (-> (user, offer) do
                             NotificationMailer.re_confirmed_translator(user).deliver
                           end),
                           sms: -> (user, offer) do
                             Yufu::SmsNotification.instance.re_confirmed_translator user
                           end

    has_notification_about :re_confirmed_client,
                           message: 'notifications.re_confirmed_client',
                           observers: -> (offer){ offer.order.owner.user },
                           mailer: -> (user, offer) do
                             NotificationMailer.re_confirmed_client(user, offer).deliver
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
        if offer.can_confirm?
          offer.order.process
          offer.notify_about_re_confirmed_translator
          if offer.translator != offer.order.offers.first.translator && offer.translator != offer.order.offers[1].translator
            offer.notify_about_re_confirmed_client
          end
        end
        offer.can_confirm?
      end

      before_transition new: :rejected do |offer|
        offer.translator.update is_banned: true
        if offer.primary?
          ban_time = 3.months
        else
          ban_time = 3.hours
        end
        BanExpireWorker.set(wait: ban_time).perform_later offer.translator.id.to_s
      end
    end

    def can_confirm?
      case
        when order.will_begin_less_than?(36.hours)
          return true
        when order.will_begin_less_than?(48.hours)
          return false unless (primary? || back_up?)
        when order.will_begin_less_than?(60.hours)
          return false unless primary?
        when !order.will_begin_less_than?(60.hours)
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

    def translator_is_not_banned
      if translator.is_banned
        errors.add :translator_id, 'is_banned'
      end
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
      if order.will_begin_less_than?(36.hours)
        confirm
      end
    end

    def order_has_primary_offer?
      order.offers.where(status: 'primary').count > 0
    end

  end
end
