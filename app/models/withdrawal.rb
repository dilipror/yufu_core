class Withdrawal
  include Mongoid::Document
  include Mongoid::Timestamps
  include Accountable

  field :sum, type: BigDecimal, default: 0

  belongs_to :user

  default_scope -> {desc :id}

  validates_presence_of :user, :sum
  validates :sum, numericality: {greater_than_or_equal_to: 0}

  state_machine initial: :new do
    state :executed
    state :rejected

    event :reject do
      transition :new => :reject
    end

    event :execute do
      transition :new => :executed
    end

    before_transition on: :execute do |withdrawal|
      if withdrawal.possible?
        transaction = withdrawal.credit_transactions.create debit: withdrawal.user, sum: withdrawal.sum
        transaction.execute
      else
        false
      end
    end
  end

  def can_create_withdrawal?(sum)
    user.withdrawals.sum(:sum) + sum.to_f < user.balance
  end

  def possible?
    user.balance >= sum if user.present?
  end
end