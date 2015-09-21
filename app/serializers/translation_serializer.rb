class TranslationSerializer < ActiveModel::Serializer
  attributes :id, :value, :original, :version_id, :is_model_localization

  def version_id
    scope.current_version.id
  end

  def id
    @object.key
  end
end
