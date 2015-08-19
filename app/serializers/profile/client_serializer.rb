class Profile::ClientSerializer < Profile::BaseSerializer
  attributes :company_name, :company_uid, :company_address, :country_id, :skype, :viber, :wechat,
             :identification_number
end
