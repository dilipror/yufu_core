FactoryGirl.define do
  factory :payment_bank, class: 'Gateway::PaymentGateway' do
    name 'Bank'
    gateway_type 'bank'
  end

  factory :payment_local_balance, class: 'Gateway::PaymentGateway' do
    name 'local balance'
    gateway_type 'local_balance'
  end
end
