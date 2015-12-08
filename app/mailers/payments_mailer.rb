class PaymentsMailer < ActionMailer::Base

  include Yufu::I18nMailerScope
  include MailerHelper
  include ActionView::Helpers::UrlHelper
  include Devise::Controllers::UrlHelpers

  before_action do
    @stored_locale = I18n.locale
  end
  after_action do
    I18n.locale = @stored_locale
  end

  def bank_payment(profile_id)
    profile = User.where(id: profile_id).first || Profile::Base.where(id: profile_id).first
    if profile.is_a? User
      mail to: profile.email, subject: I18n.t(:bill_for_bank_payment)
    else
      mail to: profile.user.email, subject: I18n.t(:bill_for_bank_payment)
    end
  end

  def remind_billing_info_2(user_id, invoice_id)
    user = User.find user_id
    invoice = Invoice.find invoice_id
    I18n.locale = invoice.subject.locale
    invoice.regenerate
    attachments['invoice.pdf'] = pdf_invoice(user, invoice)
    mail to: user.email, body: I18n.t('.body', mailer_attrs(user: user))
  end

  def send_billing_info_1(user_id, invoice_id)
    user = User.find user_id
    invoice = Invoice.find invoice_id
    BigDecimal.class_eval do
      include Humanize
    end
    I18n.locale = invoice.subject.locale
    invoice.regenerate(invoice.subject.locale)
    attachments['invoice.pdf'] = pdf_invoice(user, invoice)
    mail to: user.email, body: I18n.t('.body', mailer_attrs(user: user))
  end

  private

  def pdf_invoice(user, invoice)
    cny = Currency.where(iso_code: 'CNY').first
    gbp = Currency.where(iso_code: 'GBP').first

    sum_gbp_items = 0
    invoice.items.each do |item|
      sum_gbp_items += item.exchanged_cost('GBP')
    end

    view = ActionController::Base.new()
    view.extend(Rails.application.routes.url_helpers)
    pdf = WickedPdf.new.pdf_from_string(
        view.render_to_string(
            :template => 'application/get_pdf_invoice.slim',
            :locals => { invoice: invoice, user: user, logo_url: "#{root_url}assets/logo_small.png", cny: cny, gbp: gbp, sum_gbp_items: sum_gbp_items}
        )
    )
  end

  def mailer_attrs(params)
    {scope: scope}.merge Mailer::MailerAttrs.instance.merged_attrs params
  end
end