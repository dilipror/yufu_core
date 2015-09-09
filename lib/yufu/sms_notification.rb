class SmsNotification < ActionSMS
  def secondary_offer_confirmed(user)
    text = "【马富翻译】亲爱的 #{user.name} 非常感谢您成为此订单的核心译员/备选译员。在订单执行48/24 小时前，
        您会收到再次确认订单信息。如未能完成确认，该订单将被自动取消。请您留意。祝您生活愉快！"
    sms to: user.phone, text: text
  end
end