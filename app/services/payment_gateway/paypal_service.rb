module PaymentGateway
  module PaypalService
    PAYPAL_GATEWAY_URL = 'https://www.sandbox.paypal.com/cgi-bin/webscr'

    def self.paypal_request_uri(params)
      paypal_gw_id = Gateway::PaymentGateway.find_by(gateway_type: :paypal).id

      values = {
          cmd: '_xclick',
          charset: 'utf-8',
          business: Rails.application.secrets.merchant_email,
          return: "#{Rails.application.secrets.success_root_url}/payment-gateway/#{paypal_gw_id}/success",
          cancel_return: '/',
          # item_number: id,
          # item_name: service_name,
          currency_code: 'GBP',
          cert_id: Rails.application.secrets.cert_id,
          custom: Rails.application.secrets.ipn_return_secret,
          # amount: exchanged_cost('GBP').round(2),
          notify_url: Rails.application.secrets.notify_url
      }.merge(params)


      "#{PAYPAL_GATEWAY_URL}?cmd=_xclick&encrypted=#{encrypt_for_paypal(values)}"
      # uri = URI(PAYPAL_GATEWAY_URL)
      # uri.query = URI.encode_www_form(encrypted: encrypt_for_paypal(values))
      # uri.to_s
    end

    def self.encrypt_for_paypal(values)
      paypal_cert_rem = File.read("#{Rails.root}/certs/#{Rails.application.secrets.paypal_open_key}")
      app_cert_pem = File.read("#{Rails.root}/certs/app_cert.pem")
      app_key_pem = File.read("#{Rails.root}/certs/app_key.pem")
      signed = OpenSSL::PKCS7::sign(OpenSSL::X509::Certificate.new(app_cert_pem), OpenSSL::PKey::RSA.new(app_key_pem, ''),
                                    values.map { |k, v| "#{k}=#{v}" }.join("\n"), [], OpenSSL::PKCS7::BINARY)
      OpenSSL::PKCS7::encrypt([OpenSSL::X509::Certificate.new(paypal_cert_rem)], signed.to_der, OpenSSL::Cipher::Cipher::new("DES3"),
                              OpenSSL::PKCS7::BINARY).to_s.gsub("\n", "")
    end
  end
end


# def paypal
#   @invoice = Invoice.find params[:id]
#   paypal_params = {
#       item_number:  @invoice.id,
#       item_name:    @invoice.service_name,
#       amount:       @invoice.exchanged_cost('GBP').round(2)
#   }
#   url = PaymentGateway::PaypalService.paypal_request_uri paypal_params
#   respond_with paypal_param: {query: url}
# end