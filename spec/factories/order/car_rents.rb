# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :car_rent, :class => 'Order::CarRent' do
    duration 1
    association :car
  end
end
