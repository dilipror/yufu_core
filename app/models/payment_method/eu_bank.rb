module PaymentMethod
  class EuBank < Base
    field :email

    validates_presence_of :email
    # field :account_holder
    # field :card_number_iban
    # field :bic_swift
    #
    # validates_presence_of :account_holder, :card_number_iban, :bic_swift
  end

  # def available_currencies
  #   res = []
  #   res << Currency.find_by(iso_code: 'CNY')
  #   res << Currency.find_by(iso_code: 'GBP')
  #   res
  # end

end