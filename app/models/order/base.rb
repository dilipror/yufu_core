module Order
  class Base
    include Mongoid::Document
    include Mongoid::Timestamps
    include Notificable
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
    field :paid_time,         type: Time

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
    after_create ->(order) {CloseUnpaidJob.set(wait: 1.week).perform_later(order.id.to_s)}

    scope :writtens, -> {where _type: 'Order::Written'}
    scope :verbals, -> {where _type: 'Order::Verbal'}
    scope :local_experts, -> {where _type: 'Order::LocalExpert'}
    scope :for_everyone,-> { where is_private: false }
    scope :private,     -> { where is_private: true }
    scope :rejected,    -> { where state: 'rejected' }
    scope :wait_offer,  -> { where state: :wait_offer }

    default_scope -> {desc :id}

    has_notification_about :processing, observers: :owner, message: 'notifications.processing_order'
    has_notification_about :closing, observers: :assignee, message: 'notifications.order_closed'

    has_notification_about :cancel_not_paid_3,
                           message: 'notifications.cancel_not_paid_3',
                           observers: -> (order){ order.owner.user },
                           mailer: -> (user, order) do
                             NotificationMailer.cancel_not_paid_3(user).deliver
                           end

    # All user promoted order
    def agents
      link_agent = referral_link.try(:user)
      banner_agent =  banner.try(:user)
      [link_agent, link_agent.try(:overlord), banner_agent, banner_agent.try(:overlord), owner.try(:overlord)].compact
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

    def paid_ago?(time)
      (Time.now - paid_time) >= time if paid_time.present?
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

        if self.is_a? Order::Written
          if translation_language.is_chinese
            if assignee.chinese?
              charge_commission_to assignee.try(:user), :to_translator
            else
              charge_commission_to assignee.try(:user), 0.6
            end
          end
        else
          charge_commission_to assignee.try(:user), :to_translator
        end

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