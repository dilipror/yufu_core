module Order
  class ClientInfo
    include Mongoid::Document
    include MultiParameterAttributes
    include Personalized
    include AttributesDelegator

    field :first_name
    field :last_name
    field :email
    field :phone
    field :identification_number
    field :skype
    field :viber
    field :wechat

    belongs_to :country

    # embedded_in :order_base, class_name: 'Order::Base'
    embedded_in :invoice, class_name: 'Invoice'

    validates_presence_of :wechat, :phone, if: :persisted?

    def invoice
      @__parent
    end


    validate :company_params#, :wechat_param
    validate :uniq_phone


    # def identification_number
    #   # 'ogo'
    #   self.read_attribute :identification_number || self.invoice.subject.owner.identification_number || 'ogo'
    # end

    delegate_attributes :last_name, :first_name, :email, :phone, :identification_number, :company_name, :company_uid,
                        :company_address, :skype, :viber, :wechat, to: :invoice

    after_save :append_profile, if: -> {invoice.present? && invoice.subject.try(:owner).present?}

    def country_id
      read_attribute(:country).present? ? read_attribute(:country) : invoice.try(:subject).try(:owner).try(:country).try(:id)
    end

    def need_validate?
      present? && invoice.subject.step == 3
    end

    def uniq_phone
      tmp = User.where phone: phone
      if tmp.count > 1 || (tmp.count == 1 && tmp.first != invoice.user )
        errors.add(:phone, 'already taken')
      end
    end

    # def wechat_param
    #   if wechat.blank?
    #     errors.add 'wechat', 'is_blank'
    #   end
    # end

    def company_params
      unless company_uid.blank? && company_name.blank? && company_address.blank?
        if company_uid.blank?
          errors.add 'company_uid', 'is_blank'
        end
        if company_name.blank?
          errors.add 'company_name', 'is_blank'
        end
        if company_address.blank?
          errors.add 'company_address', 'is_blank'
        end
      end
    end

    private
    def append_profile
      append_profile_field :first_name
      append_profile_field :last_name
      append_profile_field :phone
      append_profile_field :company_name
      append_profile_field :company_uid
      append_profile_field :company_address
      append_profile_field :identification_number
      append_profile_field :skype
      append_profile_field :viber
      append_profile_field :wechat

      unless country.nil?
        vl = self.country.id
        invoice.subject.owner.write_attribute :country, vl if invoice.subject.owner.send(:country).nil? || vl.present?
      end
      invoice.subject.owner.save validate: false
    end

    def append_profile_field(field)
      value =  self.try field
      invoice.subject.owner.write_attribute field, value if invoice.subject.owner.send(field).nil? || value.present?
    end
      end
  end