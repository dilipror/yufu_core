FactoryGirl.define do
  factory :price_written, :class => 'Price::Written' do
    value 1000
    level 'document'
    increase_price 33
    association :written_type, factory: :written_type
  end

end
