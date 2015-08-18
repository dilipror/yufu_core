FactoryGirl.define do
  factory :price_base, :class => 'Price::Base' do
    value 45.5
    languages_group {build(:languages_group)}
  end
end
