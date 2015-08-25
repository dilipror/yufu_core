module Profile
  class Client < Base

    field :company_name
    field :company_uid
    field :company_address
    field :viber

    belongs_to :country
    has_many :orders, class_name: 'Order::Base', inverse_of: :owner

    validates_presence_of :identification_number, :country, :first_name, :last_name, :wechat, if: :persisted?
                                                validates_presence_of :company_uid, :company_address, if: lambda {|obj| obj.read_attribute(:company_name).present?}
        end
end