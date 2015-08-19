class PaymentMethod::BillingAddressSerializer < ActiveModel::Serializer
  attributes :id, :full_name, :address_1, :address_2, :city, :state, :zip_code, :country
end
