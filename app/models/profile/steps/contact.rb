module Profile
  module Steps
    class Contact
      include Mongoid::Document
      include Mongoid::Timestamps

      delegate :email, :email=, :additional_email, :additional_email=, :wechat, :wechat=, :skype, :skype=, :qq, :qq=,
               :phone, :phone=, :additional_phone, :additional_phone=, :custom_city, :custom_city=, :country_id, :country_id=,  to: :translator, allow_nil: true

      embedded_in :translator

      validates_presence_of :phone, :wechat, if: :persisted?
      validates :additional_email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }, allow_blank: true
      validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }
      validate :uniq_phone


      after_save do
        translator.user.password = translator.user.password_confirmation = nil
        translator.user.save!
        translator.save!
      end

      def uniq_phone
        if  User.where(phone: phone, :id.ne => translator.user_id).any?
          errors.add(:phone, 'already taken')
        end
      end

    end
  end
end