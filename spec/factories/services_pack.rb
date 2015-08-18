FactoryGirl.define do
  factory :services_pack, class: Order::ServicesPack do
    name 'sp-1'
    long_description 'long desc'
    short_description 'short desc'
  end
end