class UserSerializer < ActiveModel::Serializer

  attributes :id, :email, :can_manage_localizations, :localizations, :avatar_url,
             :duplicate_messages_on_email, :duplicate_messages_on_sms, :send_notification_on_email,
             :send_notification_on_sms, :balance, :first_name, :last_name, :middle_name, :role, :is_authorized_translator,
             :can_change_role, :sign_in_count, :duplicate_messages_on_additional_email, :duplicate_notifications_on_additional_email,
             :invitation_texts, :referral_link_url, :billing, :profile_translator_id, :profile_client_id, :is_admin, :registered_as

  has_many :invites, :permissions

  def referral_link_url
    @object.referral_link.url
  end

  def is_admin
    @object.is_a? Admin
  end

  def profile_translator_id
    @object.profile_translator.try :id
  end

  def profile_client_id
    @object.profile_client.try :id
  end

  def invitation_texts
    @object.invitation_text_ids.map  &:to_s
  end

  def avatar_url
    @object.avatar.url(:thumb)
  end

  def billing
    @object.billing.try :to_param
  end

  def localizations
    @object.localization_ids.map &:to_s
  end

  def can_change_role
    @object.can_change_role?
  end

  def balance
    @object.exchanged_balance
  end

  def invitation
    @object.invitation
  end
end
