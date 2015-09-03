module PaymentMethod
  class Alipay < Base
    field :alipay_id

    validates_presence_of :alipay_id

  end
end