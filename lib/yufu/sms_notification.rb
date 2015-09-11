module Yufu
  class SmsNotification < ActionSMS
    def offer_confirmed_for_translator(user)
      text = "【马富翻译】亲爱的 #{user.name} 非常感谢您成为此订单的核心译员/备选译员。在订单执行48/24 小时前，您会收到再次确认订单信息。如未能完成确认，该订单将被自动取消。请您留意。祝您生活愉快！"
      sms to: user.phone, text: text
    end

    def new_offer_for_translator(user)
      text = "【马富翻译】亲爱的 #{user.name},您现在是此订单的核心译员，从现在起12个小时之内请您再次 确认能否接任此订单。如未能完成确认，该订单将被自动取消。请您留意。祝您生活愉快"
      sms to: user.phone, text: text
    end
  end
end