module Order
  class Payment
    include Mongoid::Document
    include Mongoid::Timestamps
    include Accountable
    include Filterable

    # after_save :check_if_paid
    after_create :payment_gateway

    belongs_to :order, class_name: 'Order::Base', inverse_of: :payments
    belongs_to :invoice
    belongs_to :pay_way, class_name: 'Gateway::PaymentGateway'

    field :crediting_funds, type: Float, default: 0.0

    field :gateway_class

    default_scope  -> {desc :id}

    state_machine initial: :paying do

      state :paying
      state :paid
      state :partial_paid

      event :pay do
        transition [:paying, :partial_paid] => :paid
      end

      event :partial_pay do
        transition paying: :partial_paid
      end

    end

    # filtering
    def self.filter_state(state)
      where state: state
    end

    def self.filter_payment_method(method)
      gateway_ids = ::Gateway::PaymentGateway.where(gateway_type: method).distinct :id
      where :pay_way.in => gateway_ids
    end

    def self.filter_email(email)
      user_ids = User.where(email: /.*#{email}.*/).distinct :id
      invoice_ids = Invoice.where(:user_id.in => user_ids)
      where :invoice_id.in => invoice_ids
    end

    def difference_to_user
      diff = partial_sum - sum
      if diff > 0
        write_attribute :balance, diff
        Transaction.create(sum: diff, debit: self, credit: invoice.user).execute
      end
    end

    private
    def payment_gateway
      if pay_way.present?
        pay_way.afterCreatePayment
      end
    end

  end
end