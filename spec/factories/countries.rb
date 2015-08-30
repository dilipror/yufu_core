FactoryGirl.define do
  factory :country do
    name 'England'
  end

  factory :china, class: Country do
    name 'China'
    is_china true
  end

  factory :eu_country, class: Country do
    name 'some eu country'
    is_EU true
  end

  factory :hongkong_country, class: Country do
    name 'hong kong'
    is_HongKong true
  end
end
