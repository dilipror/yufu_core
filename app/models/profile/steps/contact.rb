module Profile
  module Steps
    class Contact
      include Mongoid::Document
      include Mongoid::Timestamps

      delegate :email, :email=, :additional_email, :additional_email=, :wechat, :wechat=, :skype, :skype=, :qq, :qq=,
               :phone, :phone=, :additional_phone, :additional_phone=, to: :translator, allow_nil: true

      embedded_in :translator

      validates_presence_of :phone, :wechat, if: :persisted?
      validates :additional_email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }, allow_blank: true
      validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }

      after_save do
        translator.user.password = translator.user.password_confirmation = nil
        translator.user.save!
      end
    end
  end
end