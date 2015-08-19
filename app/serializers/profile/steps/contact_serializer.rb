class Profile::Steps::ContactSerializer < Profile::Steps::BaseSerializer
  attributes :qq, :skype, :email, :additional_email, :wechat, :phone, :additional_phone
end