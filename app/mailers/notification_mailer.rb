class NotificationMailer < ActionMailer::Base
  include Yufu::I18nMailerScope

  def new_order_for_translator(user)
    mail to: user.email
  end

  def reminder_for_backup_interpreter_24(user)
    mail to: user.email, body: I18n.t('.body', scope: scope)
  end

  def reminder_for_main_interpreter_36(user)
    mail to: user.email
  end

  def reminder_to_the_client_48(user, order)
    @client = client(user)
    @order_details = order_details(order)
    @interpreter = interpreter(order)
    @backup_interpreter = backup_interpreter(order)
    mail to: user.email
  end

  # Doc's name backup-accepted
  def secondary_offer_confirmed(user)
    mail to: user.email
  end

  # Doc's name backup-int-for-client
  def secondary_offer_confirmed_for_client(user, offer)
    @client = user.full_name
    @backup_interpreter = offer.translator.user.full_name
    mail to: user.email
  end

  def cancel_int_1week(user)
    @client = client(user)
    mail to: user.email
  end

  def cancel_int_2weeks(user)
    @client = client(user)
    mail to: user.email
  end

  def cancel_int_norefund(user)
    @client = client(user)
    mail to: user.email
  end

  def inter_invoice_cancel(user)
    @client = client(user)
    mail to: user.email
  end

  def order_over_1000(user, order)
    @client = client(user)
    @order_details = order_details(order)
    mail to: user.email
  end

  # Doc's name main-inter-accepted
  def primary_offer_confirmed(user)
    mail to: user.email
  end

  def order_notification(user)
    mail to: user.email
  end

  # Doc's name primary-int
  def primary_offer_confirmed_for_client(user, offer)
    @client = user.full_name
    @order_details = order_details(offer.order)
    @interpreter = offer.translator.user.full_name
    mail to: user.email
  end

  def reminder_invoice(user, order)
    @client = client(user)
    @order_details = order_details(order)
    mail to: user.email
  end

  def service_recalled_int(user)
    @user = user
    mail to: user.email
  end

  def signup_reminder(user)
    mail to: user.email
  end

  def trans_invoice(user, order)
    @client = client(user)
    @order_details = order_details(order)
    mail to: user.email
  end

  def trans_invoice_cancel(user)
    @client = client(user)
    mail to: user.email
  end

  def trans_invoice_reminder(user, order)
    @client = client(user)
    @order_details = order_details(order)
    mail to: user.email
  end

  def trans_norefund(user)
    @client = client(user)
    mail to: user.email
  end

  def trans_cancel_immed(user)
    @client = client(user)
    mail to: user.email
  end

  def trans_confirm(user, order)
    @client = client(user)
    @order_details = order_details(order)
    mail to: user.email
  end

  def translation_completed(user)
    @client = client(user)
    mail to: user.email
  end

  def warning_interp(user)
    mail to: user.email
  end

  private

  def client(user)
    "#{user.first_name} #{user.last_name}"
  end

  def order_details(order)
    "#{order.location} - #{order.language}, #{order.meeting_in} - #{order.greeted_at_hour}:#{order.greeted_at_minute}"
  end

  def interpreter(order)
    "#{order.assignee.first_name} #{order.assignee.last_name}"
  end

  def backup_interpreter(order)
    "#{order.secondary_offer.translator.first_name} #{order.secondary_offer.last_name}"
  end

end
