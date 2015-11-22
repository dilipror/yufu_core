class ReferralLink
  include Mongoid::Document
  include PromoObject
  # include Rails.application.routes.url_helpers

  belongs_to :user, inverse_of: :referral_link

  has_many :transactions,  class_name: 'Transaction', as: :is_commission_from
  has_many :invited_users, class_name: 'User', inverse_of: :agent_referral_link, dependent: :nullify

  def href
    "#{Rails.application.config.try(:protocol)}#{Rails.application.config.try(:host)}/referral_links/#{id}"
  end
end
