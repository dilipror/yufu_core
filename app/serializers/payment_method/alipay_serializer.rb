class PaymentMethod::AlipaySerializer < PaymentMethod::BaseSerializer
  attributes  :alipay_id, :phone
end
