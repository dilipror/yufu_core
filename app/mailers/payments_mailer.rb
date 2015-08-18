class PaymentsMailer < ActionMailer::Base

  def bank_payment(profile)
    if profile.is_a? User
      mail to: profile.email, subject: I18n.t(:bill_for_bank_payment)
    else
      mail to: profile.user.email, subject: I18n.t(:bill_for_bank_payment)
    end
  end

  def send_billing_info(user, invoice)
    @invoice = invoice
    @user = user
    @logo_url = "#{root_url}assets/logo_small.png"
    BigDecimal.class_eval do
      include Humanize
    end
    mail to: user.email, subject: I18n.t(:billing_information)
  end

end