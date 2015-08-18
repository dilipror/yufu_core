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

  # TODO: Нужно переделать весь этот говнокод. В этот метод мейлера передавать тольок invite получения ФИО агента
  # и клиента сгрузить на модель invite. так же и преветсвенный текст и тело письма и адрес.
  # тело метода должна быть таким:
  # @invite = invite
  # mail(to: data[:email], subject: 'Welcome to My Awesome Site')
  # и все. В самом письме работать тольок с объектом @invite
  # 'Welcome to My Awesome Site' должно быть переведено
  def invitation(data)


    @first_name = data[:first_name]
    @last_name = data[:last_name]
    @middle_name = data[:middle_name]
    # @invite_text = data[:invite_text]
    @email = data[:email]
    @agent_name = data[:agent_name]
    @agent_surname = data[:agent_surname]
    @agent_email = data[:agent_email]
    @invite_id = data[:invite_id]


    if @first_name || @last_name || @middle_name
      @to_address = "#{I18n.t 'mailer.invitation_email.to_address'} #{@first_name} #{@middle_name} #{@last_name}!"
    else
      @to_address = I18n.t 'mailer.invitation_email.to_address_plural'
    end

    if data[:invite_text]
      @invite_text = data[:invite_text]
    else
      @invite_text = I18n.t 'mailer.invitation_email.invite_text'
    end

    if @first_name
      @on_behalf = "#{I18n.t 'mailer.invitation_email.on_behalf'} #{@agent_name}"
    else
      @on_behalf = "#{I18n.t 'mailer.invitation_email.on_behalf'} #{@agent_email}"
    end

    mail(to: data[:email], subject: 'Welcome to My Awesome Site')
    # mail(from: @agent_name + ' ' + @agent_surname + 'on behalf of Yufu.net' + @agent_email,
    #      to: @first_name + ' ' + @middle_name + ' ' + @last_name + ' ' + @agent_email,
    #      subject: 'Invitation from' + ' ' + @agent_name + ' ' + @agent_surname + ' to become a translator')
  end
end
