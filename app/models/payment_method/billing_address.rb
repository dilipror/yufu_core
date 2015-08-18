module PaymentMethod
  class BillingAddress
    include Mongoid::Document

    embedded_in :payment_method, class_name: 'PaymentMethod::Base'

    # accepts_nested_attributes_for :payment_method

    field :full_name
    field :address_1
    field :address_2
    field :city
    field :state
    field :zip_code
    field :country

    validates_presence_of :full_name, :address_1, :address_2, :city, :state, :zip_code, :country

  end
end