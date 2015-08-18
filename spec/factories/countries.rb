FactoryGirl.define do
  factory :country do
    name 'England'
  end

  factory :china, class: Country do
    name 'China'
    is_china true
  end
end
