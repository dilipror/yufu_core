module Notificable
  extend ActiveSupport::Concern

  included do
    cattr_accessor :events
  end

  def notify
    send_notification(@@events.count > 1 ? :default : @@events.keys.first)
  end

  def send_notification(event_name = :default, msg = nil)
    event = self.events[event_name]
    return nil if event.nil?

    msg ||=  event[:message]
    msg = msg.call(self) if msg.is_a? Proc

    if event[:observers].is_a?(Symbol) || event[:observers].is_a?(String)
      scope = self.send(event[:observers])
    else
      scope = event[:observers]
    end
    scope = scope.call(self) if scope.is_a? Proc
    return nil if scope.nil?
    if scope.is_a? Enumerable
      scope.each do |u|
        user = u.is_a?(User) ? u : u.try(:user)
        user.notifications.create message: msg, object: self, mailer: event[:mailer] if user.is_a?(User)
      end
    else
      user = scope.is_a?(User) ? scope : scope.try(:user)
      user.notifications.create message: msg, object: self, mailer: event[:mailer] if user.is_a?(User)
    end
  end

  module ClassMethods
    def has_notification_about(event_name = :default, options = {})
      event = {}
      event[:observers] = options[:observers] unless options[:observers].nil?
      event[:message]   = options[:message]   unless options[:message].nil?
      event[:mailer]    = options[:mailer]   unless options[:mailer].nil?
      events = self.events || {}
      events[event_name] = event
      self.events = events
      unless event_name == :default
        self.send :define_method, "notify_about_#{event_name}" do
          send_notification(event_name)
        end
      end
    end
  end
end