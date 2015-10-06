class NotificationMailer < ActionMailer::Base
  include Yufu::I18nMailerScope
  include ActionView::Helpers::UrlHelper
  include Devise::Controllers::UrlHelpers

  def new_order_for_translator(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, dashboard_link: dashboard_link)
  end

  def reminder_for_backup_interpreter_24(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, dashboard_link: dashboard_link)
  end

  def reminder_for_main_interpreter_36(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, dashboard_link: dashboard_link)
  end

  def reminder_to_the_client_48(user, order)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      order_details: order_details(order), interpreter: interpreter(order), backup_interpreter: backup_interpreter(order))
  end

  # Doc's name backup-accepted
  def secondary_offer_confirmed(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, dashboard_link: dashboard_link)
  end

  # Doc's name backup-int-for-client
  def secondary_offer_confirmed_for_client(user, offer)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: user.full_name, backup_interpreter: offer.translator.user.full_name,
                                      dashboard_link: dashboard_link)
  end

  def cancel_int_1week(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: user.full_name,
                                      balance: dashboard_link)
  end

  def cancel_int_2weeks(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: user.full_name,
                                      balance: dashboard_link)
  end

  def cancel_int_norefund(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: user.full_name)
  end

  def inter_invoice_cancel(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      new_verbal_order: (link_to I18n.t('notification_mailer.new_order'), new_verbal_order_url),
                                      dashboard_link: dashboard_link)
  end

  def order_over_1000(user, order)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      details: order_details(order),dashboard_link: dashboard_link )
  end

  # Doc's name main-inter-accepted
  def primary_offer_confirmed(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, dashboard_link: dashboard_link)
  end

  def order_notification(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, dashboard_link: dashboard_link)
  end

  # Doc's name primary-int
  def primary_offer_confirmed_for_client(user, offer)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      order_details: order_details(offer.order), interpreter: interpreter(offer.order),
                                      dashboard_link: dashboard_link)
  end

  def reminder_invoice(user, order)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      order_details: order_details(order),
                                      dashboard_link: dashboard_link)
  end

  def service_recalled_int(user)
    mail to: user.email, body: I18n.t('.body', scope: scope)
  end

  def signup_reminder(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      confirmation_url: (link_to I18n.t('notification_mailer.log_in'), confirmation_url(user, confirmation_token: user.confirmation_token) ))
  end

  def trans_invoice(user, order)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      order_details: order_details(order),
                                      dashboard_link: dashboard_link)
  end

  def trans_invoice_cancel(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      new_verbal_order: (link_to I18n.t('notification_mailer.new_order'), new_verbal_order_url),
                                      dashboard_link: dashboard_link)
  end

  def trans_invoice_reminder(user, order)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      order_details: order_details(order),
                                      dashboard_link: dashboard_link)
  end

  def trans_norefund(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      balance_url: (link_to I18n.t('notification_mailer.balance'), balance_url),
                                      dashboard_link: dashboard_link)
  end

  def trans_cancel_immed(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      balance_url: (link_to I18n.t('notification_mailer.balance'), balance_url),
                                      dashboard_link: (dashboard_link))
  end

  def trans_confirm(user, order)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      order_details: order_details(order),
                                      dashboard_link: (dashboard_link))
  end

  def translation_completed(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: (dashboard_link))
  end

  def warning_interp(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: dashboard_link)
  end

  def translator_approving(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: dashboard_link)
  end

  def become_main_int(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: dashboard_link)

  end

  def become_back_up_int(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: dashboard_link)

  end

  def for_client(user, offer)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user), client_id: offer.order.number,
                                      order_details: order_details(offer.order),
                                      interpreter_link: (link_to I18n.t('notification_mailer.your_int'), "#{asset_host}/get_pdf_translator/#{offer.translator.id.to_s}.pdf"),
                                      dashboard_link: dashboard_link)

  end


  def we_are_looking(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: dashboard_link)


  end

  def check_dates(user, order)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user), client_id: order.number,
                                      interpreter_name: "#{ order.primary_offer.try(:translator).try(:user).try(:last_name)} #{order.primary_offer.try(:translator).try(:user).try(:last_name)}",
                                      phone_number: "#{ order.primary_offer.try(:translator).try(:user).try(:phone)}",
                                      order_details: order_details(order),
                                      dashboard_link: dashboard_link)

  end

  def re_confirm_main(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: dashboard_link)
  end

  def re_confirm_back_up(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: dashboard_link)
  end

  def we_are_looking_before_24(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user))
  end

  def cancel(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user))
  end

  def re_confirmed_translator(user)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: (dashboard_link))
  end

  def re_confirmed_client(user, offer)
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user), client_id: offer.order.number,
                                      order_details: order_details(offer.order),
                                      interpreter_link: (link_to I18n.t('notification_mailer.your_int'), "#{asset_host}/get_pdf_translator/#{offer.translator.id.to_s}.pdf"),
                                      dashboard_link: dashboard_link)

  end

  private

  def dashboard_link
    link_to I18n.t('notifications.dashboard_link'), dashboard_url
  end

  def client(user)
    "#{user.first_name} #{user.last_name}"
  end

  def order_details(order)
    "#{I18n.t('notifications.order_details.location')} - #{order.location.name}, #{I18n.t('notifications.order_details.language')} -  #{order.language.name}, #{I18n.t('notifications.order_details.greeted_at')} - #{order.meeting_in}, #{formatted_time order.greeted_at_hour, order.greeted_at_minute}"
  end

  def interpreter(order)
    "#{order.assignee.try(:first_name)} #{order.assignee.try(:last_name)}"
  end

  def backup_interpreter(order)
    "#{order.secondary_offer.try(:translator).try(:first_name)} #{order.secondary_offer.try(:translator).try(:last_name)}"
  end

  def formatted_time(hour, minute)
    formatted_hour = hour < 10 ? "0#{hour}" : "#{hour}"
    formatted_minute = minute < 10 ? "0#{minute}" : "#{minute}"
    "#{formatted_hour}:#{formatted_minute}"
  end

end
