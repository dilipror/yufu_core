module PaymentMethod
  class EuBank < Base
    extend Enumerize

    field :bank_name
    field :account_holder
    field :account_num
    field :bic_swift

    enumerize :bank_name, in: ['SEPA EU  Bank', 'Other Banks', 'Chinese Bank']

    validates_presence_of :account_holder, :bic_swift
  end
end