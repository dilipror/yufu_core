module PaymentMethod
  class ChineezeBank < Base
    field :account_holder
    field :account_num
    field :full_name_of_bank
    field :address_of_branch
    field :swift

    validates_presence_of :account_holder, :account_num, :full_name_of_bank, :address_of_branch, :swift

  end
end