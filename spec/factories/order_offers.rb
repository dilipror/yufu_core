# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :order_offer, :class => 'Order::Offer' do
    order {create :order_verbal, state: :wait_offer}
    status 'primary'
    association :translator, factory: :profile_translator
  end
end
