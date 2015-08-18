# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :service_pack, :class => Order::ServicesPack do
    services {[create(:local_expert_service)]}
    need_downpayments false
  end
end
