class SmsGate
  def self.send_sms(phone, msg)
    if Rails.env.development? || Rails.env.test?
      puts "Sending sms to #{phone} with body #{msg}"
    else
      real_send(phone, msg)
    end
  end

  def self.real_send(phone, msg)
    decoded_phone = phone.gsub(/\+\(86\)/, '')
    uri = URI( "http://114.215.136.186:9008/servlet/UserServiceAPI")
    params = {username:   'mafufanyi',
              password: Base64.encode64('123456'),
              mobile: decoded_phone,
              smstype: 1,
              method: 'sendSMS',
              content:  msg.encode('gbk'),
    }
    req = Net::HTTP::Post.new(uri)
    req.set_form_data params
    req.content_type = 'application/x-www-form-urlencoded;charset=GBK'
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    res.body.force_encoding('GBK').encode('utf-8')
  rescue
    false
  end
end
