class ReferralLink
  include Mongoid::Document
  include PromoObject
  include Rails.application.routes.url_helpers

  has_many :transactions,  class_name: 'Transaction', as: :is_commission_from

  def url
    referral_link_url self
  end
end
