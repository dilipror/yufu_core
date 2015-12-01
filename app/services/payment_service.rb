class PaymentService
  def initialize(payment)
    raise ArgumentError.new('payment should be instance of Order::Payment') unless payment.is_a?(Order::Payment)
    @payment = payment
  end

  def pay!(sum)
    if @payment.can_pay?
      сrediting_funds! sum
      transfer_payment!
    else
      false
    end
  end

  private
  def сrediting_funds!(sum)
    @payment.balance += sum
    @payment.сrediting_funds += sum
    @payment.save!
    Transaction.create(sum: sum,
                       debit: @payment,
                       credit: @payment.invoice.user,
                       invoice: @payment.invoice).execute
  end

  def transfer_payment!
    if @payment.сrediting_funds >= @payment.invoice.cost
      @payment.pay && @payment.invoice.paid
    else
      @payment.partial_pay
    end
  end

end