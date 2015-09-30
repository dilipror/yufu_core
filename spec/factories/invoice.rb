FactoryGirl.define do
  factory :invoice, :class => 'Invoice' do
    state 'paying'
    association :user
    client_info {build(:client_info)}
  end
end
