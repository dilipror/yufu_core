module Order
  class Offer
    include Mongoid::Document
    include Notificable
    include Mongoid::Timestamps::Created

    STATUSES = %w(primary secondary)

    field :status, default: 'secondary'
    field :state
    field :is_confirmed, type: Mongoid::Boolean, default: false

    belongs_to :translator, class_name: 'Profile::Translator'
    belongs_to :order,      class_name: 'Order::Verbal'

    validates_presence_of :order
    # validates_inclusion_of :status, in: STATUSES
    # validates_inclusion_of :status, in: %w(secondary), on: :create, unless: :can_be_primary?
    # validates_inclusion_of :status, in: %w(primary), on: :create, unless: :can_be_secondary?
    validates_uniqueness_of :translator

    # scope :primary,   -> {where status: 'primary'}
    # scope :secondary, -> {where status: 'secondary'}

    #after_create :confirm_if_need
    # after_save
    after_save :notify_about_confirm_for_translator, :notify_about_confirm_for_client, :process_order,
               if: -> (offer) {offer.is_confirmed_changed? && offer.is_confirmed?}
    after_create :notify_about_create_offer_for_owner
    after_create :notify_about_become_main_int, if: :primary?
    after_create :notify_about_become_back_up_int, if: :back_up?
    after_create :notify_about_for_client

    has_notification_about :become_main_int,
                           message: 'notifications.become_main_int',
                           observes: :translator,
                           mailer: (-> (user, offer) do
                             NotificationMailer.become_main_int(user).deliver
                           end),
                           sms: -> (user, offer) do
                             Yufu::SmsNotification.instance.become_main_int user
                           end

    has_notification_about :become_back_up_int,
                           message: 'notifications.become_main_int',
                           observes: :translator,
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

    has_notification_about :create_offer_for_owner,
                           observers: :translator,
                           message: -> (offer) {"notifications.offers.create_offer_for_owner"},
                           sms: -> (user, offer) do
                             Yufu::SmsNotification.instance.new_offer_for_translator user
                           end

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
        end
        offer.can_confirm?
      end
    end

    def can_confirm?
      case
        when order.before_36
          return true
        when order.before_48
          return false unless (primary? || back_up?)
        when order.before_60
          return false unless primary?
        when !order.before_60
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
    def process_order
      order.process
    end

    def confirm_if_need
      if order.is_a?(Order::Written) && order.state == 'wait_offer'
        order.process
      end
      unless order.try(:first_date).nil?
        if ((order.first_date - Date.today()).day <= 1.day) && self.status == 'primary'
          order.process
        end
      end
    end

    def order_has_primary_offer?
      order.offers.where(status: 'primary').count > 0
    end

  end
end
