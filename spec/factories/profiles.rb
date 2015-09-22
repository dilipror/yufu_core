FactoryGirl.define do
  factory :profile_translator, class: Profile::Translator do
    association :user
    first_name 'name'
    last_name 'name 2'
    total_approve true
    services {[create(:service)]}
    city_approves {[create(:city_approve)]}
    wechat 'qwe'
    sequence(:phone) {|n| "9111#{n}"}
  end

  factory :full_approved_profile_translator, class: Profile::Translator do
    association :user
    first_name 'name'
    last_name 'name 2'
    total_approve true
    services {[create(:service, is_approved: true)]}
    city_approves {[create(:city_approve, is_approved: true)]}
    wechat 'weq'
    sequence(:phone) {|n| "91111#{n}"}
    # after :create do |pr|
    #   create(:city_approve, is_approved: true, translator: pr)
    # end
  end


  factory :profile_client, class: Profile::Client do
    association :user
    first_name 'name'
    last_name 'name 2'
    identification_number '0101010'
    association :country
    sequence(:phone) {|n| "911111#{n}"}
  end
end