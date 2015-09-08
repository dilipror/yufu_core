module Order
  class Base
    include Mongoid::Document
    include Mongoid::Timestamps
    include Notificable
    include Mongoid::Token
    include Sidekiq
    include Mongoid::Autoinc
    include OrderWorkflow
    include Priced

    # DEPRECATED
    token length: 9, contains: :alphanumeric

    SCOPES = %w(open in_progress close paying correct control done all_orders)
    PAY_WAYS = %w(card bank alipay credit_card local_balance)
    # [:bank, :alipay, :local_balance, :credit_card, :paypal]

    attr_accessor :do_close
    field :step, type: Integer, default: 0
    # field :pay_way
    # Private orders is available only main office. Translators should not see these
    field :is_private, type: Mongoid::Boolean, default: false

    auto_increment :number

    belongs_to :owner,           class_name: 'Profile::Base'
    belongs_to :assignee,        class_name: 'Profile::Translator'
    belongs_to :pay_way,         class_name: 'Gateway::PaymentGateway'

    # Additional Options
    embeds_one :airport_pick_up, class_name: 'Order::AirportPickUp'
    embeds_one :car_rent,        class_name: 'Order::CarRent'
    embeds_one :hotel,           class_name: 'Order::Hotel'

    has_many :payments,    class_name: 'Order::Payment', inverse_of: :order
    has_many :invoices,    inverse_of: :subject

    belongs_to :ticket, class_name: 'Support::Ticket'

    # Agent's
    belongs_to :referral_link
    belongs_to :banner

    accepts_nested_attributes_for :airport_pick_up, :car_rent, :hotel

    # before_save :create_invoice, if: -> (order) {order.step == 2}

    after_save :check_pay_way, :create_additional_services
    before_save :check_close

    scope :for_everyone,-> { where is_private: false }
    scope :private,     -> { where is_private: true }
    scope :all_orders,  -> (profile) { default_scope_for(profile).all }
    scope :open,        -> (profile) { default_scope_for(profile).where state: :wait_offer }
    scope :paying,      -> (profile) {profile.orders.where :state.in => [:new, :paying]}
    scope :in_progress, -> (profile) do
      default_scope_for(profile).where :state.in => [:in_progress, :additional_paying],
                                       connected_method_for(profile) => profile
    end
    scope :close,       -> (profile) do
      default_scope_for(profile).where :state.in => [:close, :rated], connected_method_for(profile) => profile
    end

    has_notification_about :processing, observers: :owner, message: 'notifications.processing_order'
    has_notification_about :closing, observers: :assignee, message: 'notifications.order_closed'
    # has_notification_about :paid_primary, observers: :primary_supported_translators, message: 'notifications.new_order'
    # has_notification_about :paid_secondary, observers: :secondary_supported_translators,
    #                        message: 'notifications.new_order'
    # validates_presence_of :pay_way, if: -> (order) {order.step == 3}

    def self.notify_secondary(order)
      order.notify_about_paid_secondary
    end

    # All user promoted order
    def agents
      link_agent = referral_link.try(:user)
      banner_agent =  banner.try(:user)
      [link_agent, link_agent.try(:overlord), banner_agent, banner_agent.try(:overlord), owner.try(:overlord)].compact
    end

    def offer_status_for(profile)
      offers.where(translator: profile).first.try(:status)
    end

    def office
      Office.head
    end

    def client_info
      invoices.first.try(:client_info)
    end

    def set_owner!(user)
      self.update_attribute :owner, user.profile_client
      invoices.update_all user_id: user.id
    end

    def can_update?
      true
    end

    def create_additional_services
      create_car_rent if car_rent.nil?
      create_hotel if hotel.nil?
      create_airport_pick_up if airport_pick_up.nil?
    end

    def check_pay_way
      if step == 3
        if !paid? && pay_way.present? && state == 'new'
          case pay_way.gateway_type
            when 'bank'
              payments.create gateway_class: 'Order::Gateway::Bank', pay_way: pay_way
              PaymentsMailer.bank_payment(owner).deliver
              self.paying
          end
        end
      end
    end

    def paid?
      %w(close rated wait_offer).include? state
    end

    def self.connected_method_for(profile)
      if profile.is_a? Profile::Translator
        :assignee
      else
        :owner
      end
    end

    def self.default_scope_for(profile)
      if profile.is_a? Profile::Translator
        available_for(profile).order('created_at desc')
      else
        profile.orders.order('created_at desc')
      end
    end

    def create_and_execute_transaction(debit, credit, amount)
      if debit.nil? || credit.nil?
        return false
      end
      transaction = Transaction.new(sum: amount, debit: debit, credit: credit, invoice: invoices.first)
      transaction.execute
      transaction.save
    end

    def after_paid_cashflow
      charge_commission_to referral_link.try(:user)
      charge_commission_to banner.try(:user)
      charge_commission_to owner.try(:user).try(:overlord)
    end

    def after_close_cashflow
      charge_commission_to assignee.try(:user), 30
      charge_commission_to assignee.try(:user).try(:overlord)
    end

    private
    # commission in %
    def charge_commission_to(account, commission = 3)
      cost = (invoices.first.cost || 0) * commission / 100
      if account.present?
        create_and_execute_transaction Office.head, account, cost
      end
    end

    def close_cash_flow

    end

    def check_close
      if !do_close.nil? && state == 'in_progress'
        self.close
      end
      true
    end

  end
end