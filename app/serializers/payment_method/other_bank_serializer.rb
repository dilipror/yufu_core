class PaymentMethod::OtherBankSerializer < PaymentMethod::BaseSerializer
  attributes  :account_holder, :bank_name, :account_num, :full_name_of_bank, :address_of_branch,
              :swift
end