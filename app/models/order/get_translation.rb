module Order
  class GetTranslation
    include Mongoid::Document

    embedded_in :order_written, class_name: 'Order::Written'

    field :email

    validates_format_of :email, :with => /(\A[^-][\w+\-.]*)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i,  if: -> {email.present?}
  end
end