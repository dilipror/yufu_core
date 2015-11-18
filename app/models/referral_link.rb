class ReferralLink
  include Mongoid::Document
  include PromoObject
  # include Rails.application.routes.url_helpers

  has_many :transactions,  class_name: 'Transaction', as: :is_commission_from

  def href
    "#{Rails.application.config.try(:protocol)}#{Rails.application.config.try(:host)}/referral_links/#{id}"
  end
end
