class MailerAttrs

  include Singleton
  include ActionView::Helpers::UrlHelper
  include Devise::Controllers::UrlHelpers
  include MailerHelper

  def user_attrs(user)
    if user.present?
      {client: client(user)}
    else
      {client: nil}
    end
  end

  def order_attrs(order)
    if order.present?
      {order_details: order_details(order), order_id: order.number, interpreter_name: interpreter_name(order),
       order_details: order_details(order), phone_number: phone_number(order)}
    else
      {order_details: nil, order_id: nil, interpreter_name: nil, order_details: nil}
    end
  end

  def confirm_attrs(resource, token)
    if resource.present? && token.present?
      {confirmation_url: confirm(resource, token), password_url: password_url(resource, token) }
    else
      {confirmation_url: nil, password_url: nil }
    end
  end

  def merged_attrs(user = nil, order = nil, token = nil)

  end

  def other_attrs
    {root_url: root_url, dashboard_link: dashboard_link}
  end

  private


end