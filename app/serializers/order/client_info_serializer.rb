class Order::ClientInfoSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :country_id, :email, :phone, :company_name, :company_uid, :company_address,
             :skype,:viber, :wechat, :identification_number

  def viber
    object.viber
  end
end
