FactoryGirl.define do
  factory :group do
    permissions {[build(:permission, action: :manage, subject_class: :all)]}
  end
end