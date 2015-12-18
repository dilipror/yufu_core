FactoryGirl.define do
  factory :profile_steps_personal, :class => 'Profile::Steps::Personal' do
    association :translator, factory: :profile_translator
    # birthday '2005-10-10'
    # identification_number '19239931'
    # sex 'male'
    # status 'Other'
    # years_out_of_china 23

  end

  factory :profile_steps_service, :class => 'Profile::Steps::Service' do
    association :translator, factory: :profile_translator

    hsk_level 6
    # cities {[build(:city), build(:city)]}
    # cities {[create(:city), create(:city)]}
  end

  factory :profile_steps_language, :class => 'Profile::Steps::LanguageMain' do
    association :translator, factory: :profile_translator

  end

  factory :profile_steps_contact, :class => 'Profile::Steps::Contact' do
    association :translator, factory: :profile_translator
    sequence(:phone) {|n| "91111#{n}"}

  end

  factory :profile_steps_education, :class => 'Profile::Steps::Education' do
    association :translator, factory: :profile_translator

  end



end
