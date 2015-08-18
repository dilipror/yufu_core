class Invite
  include Mongoid::Document

  field :email
  field :last_name
  field :first_name
  field :middle_name
  # field :invite_text
  field :clicked, type: Mongoid::Boolean, default: false
  belongs_to :overlord, class_name: 'User', inverse_of: :invites

  belongs_to :invitation_text, class_name: 'InvitationText'

  has_one :vassal, class_name: 'User', inverse_of: :invitation

  validates_format_of :email, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  validates_uniqueness_of :email
  validate :uniq_email_in_registered_users, unless: :persisted?
  validate :can_not_edit_accepted_invite

  scope :clicked, -> {where clicked: true}
  scope :pass_registration, -> {
    ids = User.distinct :invitation_id
    Invite.where :id.in => ids
  }

  def pass_registration?
    vassal.present?
  end

  def uniq_email_in_registered_users
    if ((User.where email: email).present? && vassal.blank?) || ((Invite.where email: email).present?)
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

end
