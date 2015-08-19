class Order::Written::WrittenTypeSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :type_name, :image_url, :active

  has_many :subtypes

  def type_name

  end

  def image_url
    @object.image.url
  end
end
