class Profile::Steps::PersonalSerializer < Profile::Steps::BaseSerializer
  attributes :years_out_of_china, :status_id, :first_name, :last_name, :birthday, :identification_number, :sex,
             :surname_in_pinyin, :name_in_pinyin, :avatar_url

  def avatar_url
    @object.avatar.try :url, :thumb
  end
end