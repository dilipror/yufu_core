module Gateway
	class PaymentGateway < Gateway::Base
    include Mongoid::Document
    include Mongoid::Paperclip
    extend Enumerize

    field :name,    localize: true
    field :tooltip, localize: true
    field :gateway_type
    field :is_active, type: Boolean
    has_and_belongs_to_many :companies

    enumerize :gateway_type , in: [:bank, :alipay, :local_balance, :credit_card, :paypal]

    has_mongoid_attached_file :image, default_url: "/no-avatar.png", style: {normal: '120x120'}
    validates_attachment_content_type :image, content_type: %w(image/jpg image/jpeg image/png)

    def afterCreatePayment

    end

    def afterPaidPayment

    end

  end
end