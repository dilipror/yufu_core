FactoryGirl.define do
  factory :transaction do
    sum 100
    association :credit, factory: :user
    association :debit, factory: :user
  end
end
