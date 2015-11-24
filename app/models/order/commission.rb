class Order::Commission
  include Mongoid::Document
  extend Enumerize
  field :key
  field :percent, type: Float

  KEYS = %w(to_senior to_partner to_partners_agent to_translators_agent to_translator)

  enumerize :key, in: KEYS

  def self.execute_transaction(key, debit, credit, price, order)
    commission = where(key: key).first
    if commission.present?
      create_and_execute_transaction debit, credit, price*commission.percent, order, commission
    else
      false
    end
  end

  def self.create_and_execute_transaction(debit, credit, amount, order, commission = nil)
    if debit.nil? || credit.nil?
      return false
    end
    transaction = Transaction.new(sum: amount, debit: debit, credit: credit, invoice: order.invoices.first, is_commission_from: commission)
    transaction.execute
    transaction.save
  end

end
