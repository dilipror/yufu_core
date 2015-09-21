module Order
  class Service
    include Mongoid::Document
    include Mongoid::Paperclip
    include BlankLocalizedFields

    field :name,              localize: true
    field :time,              type: String
    field :cost,              type: BigDecimal, default: 0
    field :downpayments,      type: BigDecimal, default: 0
    field :discount,          type: BigDecimal, default: 0
    field :support_count,     type: Boolean,    default: false
    field :is_custom,         type: Boolean,    default: false
    field :short_description, localize: true

    has_and_belongs_to_many :services_packs, :class_name => 'Order::ServicesPack'

    has_mongoid_attached_file :image, default_url: "/no-avatar.png", style: {normal: '120x120'}
    validates_attachment_content_type :image, content_type: %w(image/jpg image/jpeg image/png)

    validates_presence_of :cost, :name, :downpayments, :discount
    validates_format_of :cost, :downpayments, :discount, :with => /\A\d+(?:\.\d{0,2})?\z/
    # validates_presence_of :downpayments, unless: -> {services_packs.nil? && services_packs.try(:need_downpayments)}
    clear_localized :name, :short_description
  end
end