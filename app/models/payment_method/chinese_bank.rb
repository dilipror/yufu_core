module PaymentMethod
  class ChineseBank < Base
    extend Enumerize

    field :bank_name
    field :account_holder
    field :account_num
    field :full_name_of_bank
    field :address_of_branch
    field :swift

    enumerize :bank_name, in: ['SEPA EU  Bank', 'Other Banks', 'Chinese Bank']

    validates_presence_of :account_holder, :account_num, :full_name_of_bank, :address_of_branch
  end
end