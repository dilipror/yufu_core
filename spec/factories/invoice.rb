FactoryGirl.define do
  factory :invoice, :class => 'Invoice' do
    state 'paying'
    first_name 'vladimir'
    last_name 'putin'
    email 'r@e.net'
    association :user
    association :pay_company, factory: :gbp_company
    association :country
    association :pay_way, factory: :payment_bank
  end
end
