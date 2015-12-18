# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :order_offer, :class => 'Order::Offer' do
    association :translator, factory: :profile_translator
    association :order, factory: :order_verbal
    state 'new'

    trait :confirmed do
      state 'confirmed'
    end
  end
end
