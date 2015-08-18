FactoryGirl.define do
  factory :profile_translator, class: Profile::Translator do
    association :user
    first_name 'name'
    last_name 'name 2'
    total_approve true
    services {[create(:service)]}
    city_approves {[create(:city_approve)]}
    wechat 'qwe'
  end

  factory :full_approved_profile_translator, class: Profile::Translator do
    association :user
    first_name 'name'
    last_name 'name 2'
    total_approve true
    services {[create(:service, is_approved: true)]}
    city_approves {[create(:city_approve, is_approved: true)]}
    wechat 'weq'
    # after :create do |pr|
    #   create(:city_approve, is_approved: true, translator: pr)
    # end
  end


  factory :profile_client, class: Profile::Client do
    association :user
    first_name 'name'
    last_name 'name 2'
    wechat 'weq'
  end
end