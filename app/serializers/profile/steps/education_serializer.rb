class Profile::Steps::EducationSerializer < Profile::Steps::BaseSerializer
  has_many :educations

  def is_full
    @object.is_updated && @object.valid?
  end
end