# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :payment, :class => 'Order::Payment' do
    association :invoice
  end
end
