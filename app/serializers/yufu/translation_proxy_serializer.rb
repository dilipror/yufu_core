class Yufu::TranslationProxySerializer < ActiveModel::Serializer
  attributes :id, :value, :original

  def id
    @object.key
  end
end
