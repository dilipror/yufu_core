class PaymentMethod::EuBankSerializer < PaymentMethod::BaseSerializer
  attributes  :email, :bank_name
  # attributes  :account_holder, :card_number_iban, :bic_swift
end