FactoryGirl.define do
  factory :service, class: 'Profile::Service' do
    level "expert"
    association :language
    is_approved true
    only_written false
  end
end
