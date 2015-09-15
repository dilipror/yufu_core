class PaymentMethod::EuBankSerializer < PaymentMethod::BaseSerializer
  attributes  :account_holder, :bank_name, :account_num, :bic_swift
end