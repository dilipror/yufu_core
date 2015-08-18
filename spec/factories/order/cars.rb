# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :car, :class => 'Order::Car' do
    name 'Lada'
    cost 1.5
  end
end
