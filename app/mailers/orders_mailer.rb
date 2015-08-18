class OrdersMailer < ActionMailer::Base
  default from: "from@example.com"

  def send_translation(order)
    attachments[order.translation_file_name] = File.read(order.translation.path)
    mail to: order.get_translation.email, subject: I18n.t('frontend.order.is_done_subject')
  end

end
