FactoryGirl.define do
  factory :order_language_criterion, :class => 'Order::LanguageCriterion' do
    level 'guide'
    association :language
  end

end
