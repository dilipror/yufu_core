class PaymentMethod::OutOfChinaBankSerializer < PaymentMethod::BaseSerializer
  attributes :account_holder, :card_number_iban, :bic_swift
end
