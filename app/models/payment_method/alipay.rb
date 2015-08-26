module PaymentMethod
  class Alipay < Base
    field :alipay_id
    field :phone

    validate :check_params

    def check_params
      if alipay_id.nil? && phone.nil?
        errors.add 'params', 'is_black'
      end
    end

  end
end