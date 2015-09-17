class TranslationSerializer < ActiveModel::Serializer
  attributes :id, :value, :original, :version_id

  def version_id
    scope.current_version.id
  end

  def id
    @object.key
  end
end
