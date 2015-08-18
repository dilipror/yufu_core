module PaymentMethod
  class PayPal < Base
    field :email

    validates_presence_of :email

  end
end