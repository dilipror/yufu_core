module PaymentMethod
  class PayPal < Base
    field :email

    validates_presence_of :email

  end
  #
  # def available_currencies
  #   res = []
  #   res << Currency.find_by(iso_code: 'GBP')
  #   res
  # end

end