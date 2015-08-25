class LocalizationSerializer < ActiveModel::Serializer
  attributes :id, :name, :enable, :language_name, :language_is_for_profile, :language_id, :flag_url

  def flag_url
    @object.language.flag.exists? ? @object.language.flag.url(:thumb) : nil
  end


end
