FactoryGirl.define do
  factory :order_service, class: Order::Service do
    is_approved true
  end
end