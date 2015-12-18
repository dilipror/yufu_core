class Transaction
  include Mongoid::Document
  include Mongoid::Timestamps

  field :sum, type: BigDecimal
  field :message

  belongs_to :debit,              polymorphic: true
  belongs_to :credit,             polymorphic: true
  belongs_to :is_commission_from, polymorphic: true
  belongs_to :subject,            polymorphic: true
  belongs_to :invoice

  validates_presence_of :debit, :credit
  validates :sum, numericality: { greater_than_or_equal_to: 0 }

  scope :commissions, -> { where :is_commission_from.ne => nil}
  scope :for_user, -> (user) do
    any_of({ debit: user }, { credit: user })
  end

  default_scope -> {desc :_id}

  state_machine initial: :new do
    state :executed
    state :canceled

    event :execute do
      transition [:new, :canceled] => :executed
    end
    event :cancel do
      transition [:new, :executed] => :canceled
    end

    # It should be after, but it doesn't work with MongoId https://github.com/pluginaweek/state_machine/issues/277
    # TODO: Must be more safe. Need check that debit and credit are saved
    before_transition [:new, :canceled] => :executed do  |transaction|
      credit = transaction.credit
      debit  = transaction.debit
      credit.balance += transaction.sum
      debit.balance  -= transaction.sum
      credit.save(validate: false) && credit.save(validate: false)
    end

    before_transition :executed => :canceled do |transaction|
      credit = transaction.credit
      debit  = transaction.debit
      credit.balance -= transaction.sum
      debit.balance  += transaction.sum
      credit.save(validate: false) && credit.save(validate: false)
    end
  end

  def is_commission?
    is_commission_from.present?
  end

  def creation_date
    "#{created_at.year}-#{created_at.month}-#{created_at.day}"
  end

end
