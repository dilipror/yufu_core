class Profile::DocumentSerializer < ActiveModel::Serializer
  attributes :id, :name, :doc_url

  def doc_url
    @object.doc.url
  end

  def name
    'doc'
  end
end
