class PaymentMethod::EuBankSerializer < PaymentMethod::BaseSerializer
  attributes  :account_holder, :card_number_iban, :bic_swift
end
