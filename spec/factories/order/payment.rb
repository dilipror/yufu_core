# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :payment, :class => 'Order::Payment' do
    # payment.sum 100
    partial_sum 0
    association invoice
    association country
    association order, class: 'Order::Base'
  end
end
