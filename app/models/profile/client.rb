module Profile
  class Client < Base

    field :company_name
    field :company_uid
    field :company_address
    field :viber

    belongs_to :country
    has_many :orders, class_name: 'Order::Base', inverse_of: :owner

    validates_presence_of :wechat, :country, :phone, :first_name, :last_name, if: :persisted?
  end
end