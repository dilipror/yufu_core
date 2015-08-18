module Accountable
  extend ActiveSupport::Concern

  included do
    include Monetizeable

    field :balance, type: BigDecimal, default: 0

    has_many :debit_transactions,  class_name: 'Transaction', as: :debit
    has_many :credit_transactions, class_name: 'Transaction', as: :credit

    monetize :balance
  end
end