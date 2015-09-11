class Invite
  include Mongoid::Document

  field :email
  field :last_name
  field :first_name
  field :middle_name
  # field :invite_text
  field :clicked, type: Mongoid::Boolean, default: false
  field :expired, default: false
  belongs_to :overlord, class_name: 'User', inverse_of: :invites

  belongs_to :invitation_text, class_name: 'InvitationText'

  has_one :vassal, class_name: 'User', inverse_of: :invitation

  validates_format_of :email, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  validates_uniqueness_of :email, scope: :overlord, case_sensitive: false
  # validate :uniq_email_in_registered_users, unless: :persisted?
  validate :can_not_edit_accepted_invite
  validate :only_one_invite_until_expired, unless: :persisted?
  validates_presence_of :overlord

  after_create :run_expire_worker

  before_save :uderscore_email

  scope :clicked, -> {where clicked: true}
  scope :pass_registration, -> {
    ids = User.distinct :invitation_id
    Invite.where :id.in => ids
  }

  def to_address
    if first_name || last_name || middle_name
      "#{I18n.t 'mailer.invitation_email.to_address'} #{first_name} #{middle_name} #{last_name}!"
    else
      I18n.t 'mailer.invitation_email.to_address_plural'
    end
  end
  def agent_name
    overlord.first_name
  end

  def agent_surname
    overlord.last_name
  end

  def on_behalf
    if first_name
      "#{I18n.t 'mailer.invitation_email.on_behalf'} #{agent_name}"
    else
      "#{I18n.t 'mailer.invitation_email.on_behalf'} #{overlord.email}"
    end
  end

  def pass_registration?
    vassal.present?
  end

  def uniq_email_in_registered_users
    if ((User.where email: email.underscore).present? && vassal.blank?) || ((Invite.where email: email.underscore, expired: false).present?)
      errors.add(:email, "registered")
    end
  end

  def can_not_edit_accepted_invite
    if vassal.present?
      if vassal.email != email
        errors.add(:email, "can not edit accepted invite")
      end
    end
  end

  private
  def run_expire_worker
    ExpireInviteWorker.perform_in(24.hours, self.id)
  end

  def only_one_invite_until_expired
    if Invite.where(email: email.underscore, expired: false).present?
      errors.add(:email, "Invite for email have not expired yet")
    end
  end

  def uderscore_email
    self.email = self.email.underscore
  end

end
