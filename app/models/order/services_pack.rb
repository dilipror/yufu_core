module Order
  class ServicesPack
    include Mongoid::Document
    include Mongoid::Paperclip

    field :req_data_class_name
    field :name, localize: true
    field :short_description, localize: true
    field :long_description, localize: true
    field :title_cost, type: String, localize: true
    field :title_time, type: String, localize: true
    field :title_number, type: String, localize: true
    field :position, type: Integer

    field :meta_title, localize: true
    field :meta_description, localize: true
    field :meta_keywords, localize: true


    field :need_downpayments, type: Boolean, default: false
    field :tooltip, localize: true

    field :multi_select, type: Boolean, default: true

    has_many :orders, :class_name => 'Order::LocalExpert'
    has_and_belongs_to_many :services, :class_name => 'Order::Service'

    accepts_nested_attributes_for :services

    default_scope -> {asc :position}

    has_mongoid_attached_file :image, default_url: "/no-avatar.png", style: {original: '120x120'}
    validates_attachment_content_type :image, content_type: %w(image/jpg image/jpeg image/png)

  end
end