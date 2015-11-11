class NotificationMailer < ActionMailer::Base
  include Yufu::I18nMailerScope
  include ActionView::Helpers::UrlHelper
  include Devise::Controllers::UrlHelpers

  before_action do
    @stored_locale = I18n.locale
  end
  after_action do
    I18n.locale = @stored_locale
  end
  
  def signup_reminder(user_id)
    user = User.find user_id
    mail to: user.email, body: I18n.t('.body', mailer_attrs(user: user))
  end

  def cancel_not_paid_3(user_id)
    user = User.find user_id
    mail to: user.email, body: I18n.t('.body', scope: scope, root: root_url, client: client(user))
  end

  #old: for_client
  #replace client_id => order_id
  def order_details_4(user_id, offer_id)
    user = User.find user_id
    offer = Order::Offer.find offer_id
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user), client_id: offer.order.number,
                                      order_details: order_details(offer.order),
                                      interpreter_link: "#{Rails.application.config.host}/#{asset_host}/get_pdf_translator/#{offer.translator.id.to_s}.pdf",
                                      dashboard_link: dashboard_link)
  end

  #old: check_dates
  def check_dates_5(user_id, order_id)
    user = User.find user_id
    order = Order::Base.find order_id
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user), client_id: order.number,
                                      interpreter_name: "#{ order.primary_offer.try(:translator).try(:user).try(:last_name)} #{order.primary_offer.try(:translator).try(:user).try(:last_name)}",
                                      phone_number: "#{ order.primary_offer.try(:translator).try(:user).try(:phone)}",
                                      order_details: order_details(order),
                                      dashboard_link: dashboard_link)
  end

  def re_confirmed_client_6(user_id, offer_id)
    user = User.find user_id
    offer = Order::Offer.find offer_id
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user), client_id: offer.order.number,
                                      order_details: order_details(offer.order),
                                      interpreter_link: "#{Rails.application.config.host}/#{asset_host}/get_pdf_translator/#{offer.translator.id.to_s}.pdf",
                                      dashboard_link: dashboard_link)

  end

  def order_confirmation_7(user_id)
    user = User.find user_id
    mail to: user.email, body: I18n.t('.body', scope: scope, dashboard_link: dashboard_link, client: client(user))
  end

  def order_completed_8(user_id)
    user = User.find user_id
    mail to: user.email, body: I18n.t('.body', scope: scope, dashboard_link: dashboard_link, client: client(user))
  end

  def complete_interpreter_9(user_id)
    user = User.find user_id
    mail to: user.email, body: I18n.t('.body', scope: scope, dashboard_link: dashboard_link, client: client(user))
  end

  #old: we_are_looking
  def we_are_looking_10(user_id)
    user = User.find user_id
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: dashboard_link)
  end

  def we_are_looking_before_24_11(user_id)
    user = User.find user_id
    mail to: user.email, body: I18n.t('.body', mailer_attrs(user: user))
  end

  def cancel_12(user_id)
    user = User.find user_id
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user))
  end

  def cancel_by_user_13(user_id)
    user = User.find user_id
    mail to: user.email, body: I18n.t('.body', scope: scope, dashboard_link: dashboard_link, client: client(user))
  end

  def cancel_by_user_due_conf_delay_14(user_id)
    user = User.find user_id
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user))
  end

  def translator_approving_15(user_id)
    user = User.find user_id
    I18n.locale = 'zh-CN'
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: dashboard_link)
  end

  def new_order_for_translator_16(user_id)
    user = User.find user_id
    I18n.locale = 'zh-CN'
    mail to: user.email, body: I18n.t('.body', scope: scope, dashboard_link: dashboard_link, client: client(user))
  end

  # old: become_main_int
  def become_main_int_17(user_id)
    user = User.find user_id
    I18n.locale = 'zh-CN'
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: dashboard_link)
  end

  #old: become_back_up_int
  def become_back_up_int_18(user_id)
    user = User.find user_id
    I18n.locale = 'zh-CN'
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: dashboard_link)
  end

  #old: re_confirm_main
  def re_confirm_main_19(user_id)
    user = User.find user_id
    I18n.locale = 'zh-CN'
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: dashboard_link)
  end

  def re_confirm_back_up_20(user_id)
    user = User.find user_id
    I18n.locale = 'zh-CN'
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: dashboard_link)
  end

  def re_confirmed_translator_21(user_id)
    user = User.find user_id
    I18n.locale = 'zh-CN'
    mail to: user.email, body: I18n.t('.body', scope: scope, client: client(user),
                                      dashboard_link: (dashboard_link))
  end

  private

  def interpreter(order)
    "#{order.assignee.try(:first_name)} #{order.assignee.try(:last_name)}"
  end

  def backup_interpreter(order)
    "#{order.secondary_offer.try(:translator).try(:first_name)} #{order.secondary_offer.try(:translator).try(:last_name)}"
  end

  def mailer_attrs(params)
    {scope: scope}.merge Mailer::MailerAttrs.instance.merged_attrs params
  end

end
