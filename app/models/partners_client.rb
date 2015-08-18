# Model for partner's client. It isn't independent user. Need only for partner's backoffice.
# Partner can assign self order with partners_client entity
class PartnersClient
  include Mongoid::Document
  include Mongoid::Timestamps
  include Personalized

  has_many :orders, class_name: 'Order::Base'
end
