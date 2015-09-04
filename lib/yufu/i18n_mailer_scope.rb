module Yufu
  module I18nMailerScope
    def scope
      "#{self.class.name.to_s.underscore}.#{@_action_name}"
    end
  end
end
