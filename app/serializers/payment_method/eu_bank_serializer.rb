class PaymentMethod::EuBankSerializer < PaymentMethod::BaseSerializer
  attributes  :email
  # attributes  :account_holder, :card_number_iban, :bic_swift
end