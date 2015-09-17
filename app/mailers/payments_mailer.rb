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
    view = ActionController::Base.new()
    # include helpers and routes
    view.extend(Rails.application.routes.url_helpers)
    pdf = WickedPdf.new.pdf_from_string(
        view.render_to_string(
            :template => 'application/get_pdf_invoice.slim',
            :locals => { invoice: invoice, user: user, logo_url: "#{root_url}assets/logo_small.png"}
        )
    )
    BigDecimal.class_eval do
      include Humanize
    end
    attachments['invoice.pdf'] = pdf
    mail to: user.email, subject: I18n.t(:billing_information)
  end

end