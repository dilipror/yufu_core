module Yufu
  class SmsNotification < ActionSMS
    include ActionView::Helpers::UrlHelper
    include Devise::Controllers::UrlHelpers

    def offer_confirmed_for_translator(user)
      text = "【马富翻译】亲爱的 #{user.name} 非常感谢您成为此订单的核心译员/备选译员。在订单执行48/24 小时前，您会收到再次确认订单信息。如未能完成确认，该订单将被自动取消。请您留意。祝您生活愉快！"
      sms to: user.phone, text: text
    end

    def new_offer_for_translator(user)

    end

    def translator_approving(transaltor)
      text = "【马富翻译】亲爱的XXX, 恭喜您成功加入语富。请保管好您的语富账号跟密码，所有订 单详情都会在此账户显示，请您留意以免错失订单。感谢您的合作并祝您生活愉快！"
      sms to: transaltor.phone, text: text
    end

    def become_main_int(user)

      text = "【语富翻译】订单确认:亲爱的 #{client(user)},恭喜您成为此订单的核心译员。您会在订单执行前60小时

      收到再次确认订单的信息。如未能再次确认订单,该订单则由其他译员接手,同时您的账号将被

      冻结3个月。请您留意。祝您生活愉快!

      #{dashboard_url}"
      sms to: user.phone, text: text
    end

    def become_back_up_int
      text = "【语富翻译】订单确认:亲爱的 #{client(user)},恭喜您成为此订单的备选译员。您会在订单执行前48小时
              收到再次确认订单的信息。请您留意。祝您生活愉快!"
      sms to: user.phone, text: text
    end

    def re_confirm_main(user)
      text = "【语富翻译】再次确认订单:亲爱的 #{client(user)},目前您是此订单的核心译员,从现在起12个小时之内
                请您尽快再次确认能否执行此订单。如未能完成确认,该订单则由备选译员接手,同时您的账号
                将被冻结3个月。请您留意。祝您生活愉快!
                #{dashboard_url}"
      sms to: user.phone, text: text
    end

    def re_confirm_back_up(user)
      text = "【语富翻译】再次确认订单:亲爱的 #{client(user)},目前您是此订单的备选译员。从现在起12个小时之内
              请您尽快再次确认订单,您将有可能成为此订单的核心译员。请您留意。祝您生活愉快!"
      sms to: user.phone, text: text
    end

    def re_confirmed_translator(user)
      text = "【语富翻译】恭喜您:亲爱的 #{client(user)},恭喜您成为此订单的译员。请到您的语富信息窗查看订单详
              情,以免耽误订单执行。感谢您的合作并祝您生活愉快!
              #{dashboard_url}"
      sms to: user.phone, text: text
    end

    def client(user)
      "#{user.first_name} #{user.last_name}"
    end

    def dashboard_url
      "#{Rails.application.config.host}/office"
    end

  end
end
