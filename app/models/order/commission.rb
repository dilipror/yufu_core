class Order::Commission
  include Mongoid::Document
  field :key
  field :percent, type: Float

  def self.execute_transaction(key, debit, credit, price, order)
    commission = where(key: key).first
    if commission.present?
      order.create_and_execute_transaction debit, credit, price*commission.percent, commission
    else
      false
    end
  end

end
