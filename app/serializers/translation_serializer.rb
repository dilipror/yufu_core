class TranslationSerializer < ActiveModel::Serializer
  attributes :id, :value, :original, :storage

  def id
    @object.key
  end
end
