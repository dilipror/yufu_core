FactoryGirl.define do
  factory :price_verbal, :class => 'Price::Verbal' do
    value 1000
    level 'guide'
  end

end
