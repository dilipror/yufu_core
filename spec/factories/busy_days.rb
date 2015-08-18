FactoryGirl.define do
  factory :busy_day do
    date "2014-01-19"
  end

  factory :hold_day, class: BusyDay do
    date "2014-01-19"
    association :order_verbal
  end

end
