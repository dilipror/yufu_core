module PaymentMethod
  class InternationalCreditCard < Base
    field :card_number

    validates_presence_of :card_number

  end
end