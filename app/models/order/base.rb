module Order
  class Base
    include Mongoid::Document
    include Mongoid::Timestamps
    include Notificable
    include Sidekiq
    include Mongoid::Autoinc
    include OrderWorkflow
    include Priced

    SCOPES = %w(open in_progress close paying correct control done all_orders rejected)
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

    has_many :payments,    class_name: 'Order::Payment', inverse_of: :order
    has_many :invoices,    inverse_of: :subject

    belongs_to :ticket, class_name: 'Support::Ticket'

    # Agent's
    belongs_to :referral_link
    belongs_to :banner

    # before_save :create_invoice, if: -> (order) {order.step == 2}

    after_save :check_pay_way
    before_save :check_close

    scope :for_everyone,-> { where is_private: false }
    scope :private,     -> { where is_private: true }
    scope :rejected,    -> { where state: 'rejected' }
    scope :wait_offer,  -> { where state: :wait_offer }
    scope :opened,      -> (profile) { default_scope_for(profile).where state: :wait_offer }
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

    def set_owner!(user)
      self.update_attribute :owner, user.profile_client
      invoices.update_all user_id: user.id
    end

    def can_update?
      true
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

    def create_and_execute_transaction(debit, credit, amount, commission = nil)
      if debit.nil? || credit.nil?
        return false
      end
      transaction = Transaction.new(sum: amount, debit: debit, credit: credit, invoice: invoices.first, is_commission_from: commission)
      transaction.execute
      transaction.save
    end

    def senior
      nil
    end

    def after_close_cashflow
      unless is_private
        charge_commission_to assignee.try(:user), :to_translator
        charge_commission_to senior.try(:user), :to_senior
      end
      charge_commission_to referral_link.try(:user), :to_partner
      charge_commission_to banner.try(:user), :to_partner
      charge_commission_to referral_link.try(:user).try(:overlord), :to_partners_agent
      charge_commission_to banner.try(:user).try(:overlord), :to_partners_agent
      charge_commission_to assignee.try(:user).try(:overlord), :to_translators_agent
    end

    private
    # commission in %
    def charge_commission_to(account, key)
      cost = (invoices.first.cost || 0) * 0.95
      Order::Commission.execute_transaction key, Office.head, account, cost, self
    end


    def check_close
      if !do_close.nil? && state == 'in_progress'
        self.close
      end
      true
    end

  end
end