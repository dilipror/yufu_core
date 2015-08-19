class ServicesPackSerializer < ActiveModel::Serializer
  attributes :id, :name, :short_description, :long_description, :image_url,
             :multi_select, :tooltip, :need_downpayments,
             :title_time, :title_cost, :title_number

  has_many :services
  # def services_ids
  #   @object.services.map &:id
  # end

  def image_url
    @object.image.url
  end

end
