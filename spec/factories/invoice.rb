FactoryGirl.define do
  factory :invoice, :class => 'Invoice' do
    state 'paying'
    association :user
  end
end
