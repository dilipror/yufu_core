module PaymentMethod
  class EuBank < Base
    extend Enumerize

    field :email
    field :bank_name

    enumerize :bank_name, in: ['SEPA EU  Bank', 'Other Banks', 'Chinese Bank']

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