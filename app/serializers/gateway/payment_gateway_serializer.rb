class Gateway::PaymentGatewaySerializer < ActiveModel::Serializer
  attributes :id, :name, :tooltip, :is_active, :gateway_type, :image_url, :company_ids, :title, :description

  def image_url
    @object.image.url
  end
end