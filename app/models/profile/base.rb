module Profile
  class Base
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Token

    delegate :first_name, :middle_name, :last_name, :chinese_name, :chinese_name=, :first_name=, :last_name=,
             :middle_name=, :email, :avatar,
             :avatar_file_size, :avatar_file_name, :avatar_content_type, :avatar_file_size=, :avatar_file_name=,
             :avatar_content_type=, :avatar=, :phone, :phone=, :wechat, :wechat=, :sex, :sex=, :birthday, :birthday=,
             :skype, :skype=, :qq, :qq=, :additional_email, :additional_email=, :additional_phone, :additional_phone=,
             :name_in_pinyin, :surname_in_pinyin, :name_in_pinyin=, :surname_in_pinyin=, :identification_number,
             :identification_number=, to: :user, allow_nil: true

    field :total_approve, type: Boolean, default: false
    field :_type

    belongs_to :profile_language, class_name: 'Language'
    belongs_to :user

    validates_presence_of :user
    validates_format_of :additional_email, :with => /(\A[^-][\w+\-.]*)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i,  if: -> {additional_email.present?}

    after_save if: -> {user.changed? && !user.confirmed_at.nil?} do
      user.save
    end

    def to_param
      token
    end

    def can_update?
      new? || reopen?
    end
    token length: 9, contains: :alpha_lower
  end
end