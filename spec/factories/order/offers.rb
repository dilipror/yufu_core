# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :offer, :class => 'Order::Offer' do
    status 'primary'
    # association :profile_translator#, class: 'Profile::Translator'
    # association :order_verbal, class: 'Order::Verbal'
  end
end
