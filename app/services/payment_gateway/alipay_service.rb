require 'openssl'
require 'base64'

module PaymentGateway
  module AlipayService
  ALIPAY_GATEWAY_URL = 'https://mapi.alipay.net/gateway.do'
  RSA_KEY = <<-EOF
    -----BEGIN RSA PRIVATE KEY-----
    MIICXgIBAAKBgQDTB0Ql+bx+DlKLS6iyXyKnGSghCaoX+UXEx+2B059rYbirXm7X
    aKHQ6MFKoWHrZTaYLaxh7wnWTGKNyJlv8QKyoBWMDd6sfQAu3Wm/5OD9JQ9lzWxP
    cjRoL41VfXAD6k2LF2lIdMnp4HBDETUndt8LHFMXdFSextgX16VwhVWbawIDAQAB
    AoGBAJnDnKNzIiZTt0+qNGSsL2rESNox2Y+YYX7uEqBbm7i5vr6Xk3o/0lCPmHAR
    wXCtEie2d/nwHCHbDKC0/yBy43wDfqmhsCw6uTCpnnNWL9lrshtzSrMjXQkpTTFg
    M75ZNbstvmUxAI+m7Q2jOuh7P7G8PwH6npD63r2r7HfWcbd5AkEA8KP9CKLCuJ/d
    BbW8DQAX4SccwM1H3w2noZEGrUbNLPQrQ32Mjg8DIfb5Yca2irA0ujrW993hTwc8
    Ij3NM7soLwJBAOB/a9yVTpMK9ghSHTfsei2PaqY/j13XacERYMUkxwNRxTzftFW8
    D6ftZZ/3tCGweav4Nr3161rsB6NGATy4NYUCQQCtx7+T3PaCHfCfjv6e5NJZ5sT8
    90JP8qx8IR+RQvAo5qvXsXMvo+e/P3wZAEgTH+z0EEnt9m4fhDoJAFiQYzhBAkAO
    6ig+VWUM+9NwphPu3TUYxchuFxbtQxxxiTgGoPTf0ZTrAGm4sG/R1kHEKO68tj6/
    IBRy9l2WgsvXGxWF9S8JAkEAjZ7PCrVJIcwlYSsi1O2SvvmNS8jGvuQmYHGIBu5n
    ph8PxK05ikpd1VBTh4y6UXQSVY2B902a0dKObsax54IADg==
    -----END RSA PRIVATE KEY-----
        EOF

      # partner - A unique partner ID to identify a contracted Alipay Account
      # out_trade_no - invoice id
      # subject - service name(interpretation service, etc)
      # logistics_type - post or express
      # logistics_fee - 0
      # logistics_payment - 'SELLER_PAY'
      # CREATE_PARTNER_TRADE_BY_BUYER_REQUIRED_PARAMS = %w( out_trade_no subject logistics_type logistics_fee logistics_payment price quantity )
      NECESSARY = %w(service partner _input_charset sign_type sign out_trade_no subject payment_type)
      def self.alipay_request_uri(params)
        params = stringify_keys(params)
        # check_required_params(params, CREATE_PARTNER_TRADE_BY_BUYER_REQUIRED_PARAMS)

        params = {
            'service'        => 'create_forex_trade',
            'partner'        => '2088101011913539', # secrets
            '_input_charset' => 'utf-8',
            'payment_type'   => '1',
            'notify_url'     => 'http://6c01d3dc.ngrok.com/alipay_respond',
            'return_url'     => '/',
            'quantity'       => '1'
        }.merge(params)


        # params = {'body'=>'goods',
        # 'currency'=>'USD',
        # 'notify_url'=>'http://www.tabao.com',
        # 'out_trade_no'=>'6445714259642100',
        # 'partner'=>'2088002007018916',
        # 'return_url'=>'http://www.tabao.com',
        # 'service'=>'create_forex_trade',
        # 'subject'=>'goods',
        # 'total_fee'=>'13'}

        request_uri(params).to_s
      end

      def self.stringify_keys(hash)
        new_hash = {}
        hash.each do |key, value|
          new_hash[(key.to_s rescue key) || key] = value
        end
        new_hash
      end

      def self.check_required_params(params, names)
        names.each do |name|
          warn("Alipay Warn: missing required option: #{name}") unless params.has_key?(name)
        end
      end

      def self.request_uri(params)
        uri = URI(ALIPAY_GATEWAY_URL)
        uri.query = URI.encode_www_form(sign_params(params))
        uri
      end

      def self.sign_params(params, options = {})
        params.merge(
            'sign_type' => 'MD5',
            'sign'      => alipay_sign_generate(params)
        )
      end

      def self.alipay_sign_generate(params)
        params = stringify_keys(params)
        sign_type = 'MD5'
        key = '760bdzec6y9goq7ctyx96ezkz78287de'
        string = params_to_string params
        md5_sign key, string

      end

      def self.md5_sign(key, string)
        Digest::MD5.hexdigest("#{string}#{key}")
      end

      def self.verify?(key, string, sign)
        sign == sign(key, string)
      end

      def self.params_to_string(params)
        params.sort.map { |item| item.join('=') }.join('&')
      end
  end
end