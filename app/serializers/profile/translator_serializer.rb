class Profile::TranslatorSerializer < Profile::BaseSerializer
  attributes :state, :one_day_passed, :status

  has_many :city_approves

  has_one :profile_steps_service
  has_one :profile_steps_education
  has_one :profile_steps_personal
  has_one :profile_steps_language
  has_one :profile_steps_contact

  def one_day_passed
    @object.one_day_passed?
  end

  def status
    @object.status
  end
end
