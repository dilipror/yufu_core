FactoryGirl.define do
  factory :payment_method, class: PaymentMethod::PayPal do
    email 'email@example.com'
  end
end
