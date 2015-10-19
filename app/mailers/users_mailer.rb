require 'mailer_helper'

class UsersMailer < ActionMailer::Base
  include Yufu::I18nMailerScope
  add_template_helper MailerHelper
  include Devise::Controllers::UrlHelpers

  def create(user, need_send_password = false)
    @user = user
    @need_send_password = need_send_password
    mail to: user.email, subject: t('devise.registrations.mailer.subject')
  end

  def new_notification(notification)
    @notification = notification
    @user = @notification.user
    if @user.present?
      mail to: @user.email, subject: t('new_notification')
    end
  end

  # 'Welcome to My Awesome Site' должно быть переведено
  def invitation(invitation)
    @invitation = invitation

    mail(to: invitation.email, subject: 'Welcome to My Awesome Site')
  end

  def confirmation_reminder(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: user.email,  confirm: (confirmation_url(user, confirmation_token: user.confirmation_token)))
  end
end
