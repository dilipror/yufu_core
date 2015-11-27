module Order
  class RejectService
    def initialize(order)
      @order = order
    end

    def reject_order(inner = :client)
      if @order.can_reject? inner
        refund inner
        @order.reject inner
      end
    end

    def refund(inner = :client)
      if @order.paid? && @order.owner.present?
        sum = calculate_sum inner
        if sum > 0
          tr = Transaction.create debit: Office.head,
                                  credit: @order.owner.user,
                                  sum: sum,
                                  message: 'Refund',
                                  subject: @order
          tr.execute
        end
      end
    end

    def cost
      @order.invoices.first.try(:cost) || 0
    end

    def full_with_cover
      cost + 192
    end

    def full; cost end

    def sector_zero
      0
    end

  end
end