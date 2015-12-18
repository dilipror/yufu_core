FactoryGirl.define do
  factory :level_up_request, class: 'Profile::LevelUpRequest' do
    from 1
    to 2
    association :service
  end
end
