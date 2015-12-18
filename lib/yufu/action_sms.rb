module Yufu
  class ActionSMS
    include Singleton

    class SMS
      attr_accessor :to, :text

      def initialize(to: nil, text: nil)
        @to = to
        @text = text
      end

      def deliver
        SmsGate.send_sms @to, @text
      end
    end

    def sms(options = {})
      SMS.new to: options[:to], text: options[:text]
    end
  end
end