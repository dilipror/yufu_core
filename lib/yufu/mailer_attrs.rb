require File.expand_path('../../../app/helpers/yufu_helper', __FILE__)


module Mailer
  class MailerAttrs

    include Singleton
    include ActionView::Helpers::UrlHelper
    include Devise::Controllers::UrlHelpers
    include YufuHelper

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
         phone_number: phone_number(order)}
      else
        {order_details: nil, order_id: nil, interpreter_name: nil, phone_number: nil}
      end
    end

    def confirm_attrs(confirmation_url, password_url)
      if confirmation_url.present? && password_url.present?
        {confirmation_url: confirmation_url, password_url: password_url }
      else
        {confirmation_url: nil, password_url: nil }
      end
    end

    def other_attrs
      {root_url: root_url, dashboard_link: dashboard_link}
    end

    def merged_attrs(params = {})
      user_attrs(params[:user]).merge(order_attrs(params[:order])).merge(
          confirm_attrs(params[:confirmation_url], params[:password_url])).merge other_attrs
    end

    private
    def client(user)
      "#{user.first_name} #{user.last_name}"
    end

    def dashboard_link
      dashboard_url
    end

    def order_details(order)
      "#{I18n.t('notifications.order_details.location')} - #{order.location.name}, #{I18n.t('notifications.order_details.language')} -  #{order.language.name}, #{I18n.t('notifications.order_details.greeted_at')} - #{order.meeting_in}, #{formatted_time order.greeted_at_hour, order.greeted_at_minute}"
    end

    def interpreter_name(order)
      "#{ order.primary_offer.try(:translator).try(:user).try(:last_name)} #{order.primary_offer.try(:translator).try(:user).try(:last_name)}"
    end

    def phone_number(order)
      "#{ order.primary_offer.try(:translator).try(:user).try(:phone)}"
    end

    def confirm(resource, token)
      confirmation_url(resource, confirmation_token: token, locale: Localization.get_current.name)
    end

    def password_url(resource, token)
      edit_password_url(resource, reset_password_token: token)
    end

    def formatted_time(hour, minute)
      formatted_hour = hour < 10 ? "0#{hour}" : "#{hour}"
      formatted_minute = minute < 10 ? "0#{minute}" : "#{minute}"
      "#{formatted_hour}:#{formatted_minute}"
    end
  end
end