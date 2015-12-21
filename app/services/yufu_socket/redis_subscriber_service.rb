require 'faye/websocket'

module YufuSocket    
  class RedisSubscriberService < BaseRedisService

    class << self
      attr_accessor :clients
    end

    attr_reader :base_channel

    def initialize(clients,base_channel)
      self.class.clients = clients
      @base_channel = base_channel
    end

    def process
        # Create a new pattern-based subscription that will listen for new messages on any channel
        # that matches the pattern "websockets.*".
        connection.psubscribe("#{base_channel}.*") do |on|
          # When a message is received, execute the send_message method
          on.pmessage do |pattern, channel, msg|
            send_message(channel, msg)
          end
        end
    end


    def send_message(channel, msg)
      # For every client that has connected

      self.class.clients.each do |client|

        channel_name = channel.gsub("#{base_channel}.", "")

        # If the client has requested a subscription to this channel
        if client[:channels].include?(channel_name)

          # Send the client the message, including the channel on which it
          # was received.
          message = "{\"channel\":\"#{channel_name}\",\"message\":#{msg}}"
          client[:ws].send(message)
        end
      end
    end

  end
end  