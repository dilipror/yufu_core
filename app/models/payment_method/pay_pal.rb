module PaymentMethod
  class PayPal < Base
    field :email

    validates_presence_of :email
    validates_format_of :email, :with => /(\A[^-][\w+\-.]*)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i,  if: -> {email.present?}

  end
end