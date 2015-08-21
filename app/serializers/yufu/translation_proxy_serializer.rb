class Yufu::TranslationProxySerializer < ActiveModel::Serializer
  attributes :id, :value, :original, :version_id

  def id
    @object.key
  end
end
