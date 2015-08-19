class PaymentMethod::ChineezeBankSerializer < PaymentMethod::BaseSerializer
  attributes  :account_holder, :account_num, :full_name_of_bank, :address_of_branch, :swift
end
