class Profile::Steps::BaseSerializer < ActiveModel::Serializer
  attributes :id, :profile_id, :is_full

  def is_full
    @object.valid?
  end

  def profile_id
    @object.translator.token
  end
end