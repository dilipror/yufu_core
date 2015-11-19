module AgentSystem
  extend ActiveSupport::Concern

  included do
    has_many   :invitation_texts
    belongs_to :invitation, class_name: 'Invite', inverse_of: :vassal
    belongs_to :overlord, class_name: 'User'
    # promo objects through which user has been registered
    belongs_to :agent_referral_link, class_name: 'ReferralLink', inverse_of: :invited_users
    belongs_to :agent_banner, class_name: 'Banner', inverse_of: :invited_users
    # end
    has_one    :referral_link, inverse_of: :user, dependent: :destroy
    has_many   :banners, inverse_of: :user, dependent: :destroy
    has_many   :vassals, class_name: 'User', dependent: :nullify
    has_many   :invites, class_name: 'Invite', dependent: :nullify, inverse_of: :overlord

    before_create :add_invite
    before_create :set_overlord
    after_create  :cretate_defualt_agent_system
  end

  def promoted_get?(order)
    order.agents.include? self
  end

  protected
  def cretate_defualt_agent_system
    create_referral_link if referral_link.nil?
    create_banners if banners.empty?
    create_billing if billing.nil?
    create_default_invitation_texts if invitation_texts.empty?
  end

  def create_default_invitation_texts
    invitation_texts << InvitationText.create(text: I18n.t('mailer.invitation_email.invite_text_client'),
                                              name: I18n.t('mailer.invitation_email.name_invite_text_client'))

    invitation_texts << InvitationText.create(text: I18n.t('mailer.invitation_email.invite_text_translator'),
                                              name: I18n.t('mailer.invitation_email.name_invite_text_translator'))

    invitation_texts << InvitationText.create(text: I18n.t('mailer.invitation_email.invite_text_partner'),
                                              name: I18n.t('mailer.invitation_email.name_invite_text_partner'))

  end

  def create_banners
    banners.create name: 'default_banner_one'
    banners.create name: 'default_banner_two'
    banners.create name: 'default_banner_three'
  end

  def set_overlord
    set_overlord_from(agent_referral_link) ||
        set_overlord_from(agent_banner) ||
        set_overlord_from(invitation, :overlord)
    true
  end

  def add_invite
    if invitation.nil? && Invite.where(email: email.downcase, expired: false).present?
      self.invitation = Invite.where(email: email.downcase, expired: false).first
    end
  end

  def set_overlord_from(object, owner_method = :user)
    result = false
    if object.present?
      owner = object.try owner_method
      if owner.present? && owner.is_a?(User)
        self.overlord = owner
        result = true
      end
    end
    result
  end
end