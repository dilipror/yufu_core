# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :local_expert_service_order, :class => Order::ServiceOrder do
    service {create :local_expert_service}
  end
end
