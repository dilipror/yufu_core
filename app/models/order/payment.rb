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

    field :sum, type: Float
    field :partial_sum, type: Float, default: 0.0
    # field :state#, default: 'paying'
    field :gateway_class

    state_machine initial: :paying do

      state :paying
      state :paid
      state :partial_paid

      event :to_pay do
        transition [:paying, :partial_paid] => :paid
      end

      event :to_partial_pay do
        transition paying: :partial_paid
      end

      before_transition on: :to_pay do |payment|
        payment.pay
        payment.difference_to_user
        payment.order.paid
        true
      end

    end

    # def to_pay
    #   pay
    #   difference_to_user
    #   order.paid
    # end

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


      # user_ids = User.where(email: /.*#{email}.*/).distinct :id
      # profile_ids = Profile::Base.where(:user_id.in => user_ids).distinct :id
      # order_ids = Order::Base.where(:owner_id.in => profile_ids).distinct :id
      # where :order_id.in => order_ids
    end

    def difference_to_user
      diff = partial_sum - sum
      if diff
        write_attribute :balance, diff
        Transaction.create(sum: diff, debit: self, credit: invoice.user).execute
      end
    end

    def pay
      write_attribute :balance, sum
      Transaction.create(sum: sum, debit: self, credit: invoice.user, invoice: invoice).execute
      invoice.paid
      if pay_way.present?
        pay_way.afterPaidPayment
      end
    end

    def partial_pay(partial_sum)
      write_attribute :partial_sum, self.partial_sum + partial_sum
      if self.partial_sum >= sum
        to_pay
      else
        to_partial_pay
      end
      true
    end

    private
    # def check_if_paid
    #   if state_changed? && state == 'paid'
    #     order.paid
    #   end
    #   # if state_changed? && state_was == 'paid' && state == 'paying'
    #   #   order.unpaid
    #   # end
    #   true
    # end

    def payment_gateway
      if pay_way.present?
        pay_way.afterCreatePayment
      end
    end

  end
end