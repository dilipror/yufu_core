require 'mailer_helper'

class UsersMailer < ActionMailer::Base
  add_template_helper MailerHelper

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
end
