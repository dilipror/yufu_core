module PaymentMethod
  class OutOfChinaBank < Base
    field :account_holder
    field :card_number_iban
    field :bic_swift

    validates_presence_of :account_holder, :card_number_iban, :bic_swift

  end
end