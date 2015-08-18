FactoryGirl.define do
  factory :languages_group do
    verbal_prices {[build(:price_verbal)]}
    written_prices {[build(:price_written)]}
  end

end
