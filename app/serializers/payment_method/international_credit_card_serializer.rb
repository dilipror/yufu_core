class PaymentMethod::InternationalCreditCardSerializer < PaymentMethod::BaseSerializer
  attributes :card_number
end
