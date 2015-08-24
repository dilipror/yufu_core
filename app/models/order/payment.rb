module Order
  class Payment
    include Mongoid::Document
    include Accountable

    after_save :check_if_paid
    after_create :payment_gateway

    belongs_to :order, class_name: 'Order::Base', inverse_of: :payments
    belongs_to :invoice
    belongs_to :pay_way, class_name: 'Gateway::PaymentGateway'

    field :sum, type: Float
    field :state, default: 'paying'
    field :gateway_class

    def pay
      write_attribute :balance, sum
      Transaction.create(sum: sum, debit: self, credit: invoice.user, invoice: invoice).execute
      invoice.paid
      if pay_way.present?
        pay_way.afterPaidPayment
      end
    end

    def paid
      update_attribute :state, 'paid'
    end

    def unpaid
      update_attribute :state, 'paying'
    end

    private
    def check_if_paid
      if state_changed? && state == 'paid'
        order.paid
      end
      if state_changed? && state_was == 'paid' && state == 'paying'
        order.unpaid
      end
      true
    end

    def payment_gateway
      if pay_way.present?
        pay_way.afterCreatePayment
      end
    end

  end
end