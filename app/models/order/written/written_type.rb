class Order::Written::WrittenType
  include Mongoid::Document
  include Mongoid::Paperclip

  field :name,        localize: true
  field :description, localize: true
  field :type_name
  field :active, default: true, type: Boolean
  field :position, type: Integer

  has_many :subtypes, class_name: 'Order::Written::WrittenSubtype'

  has_mongoid_attached_file :image, default_url: "/no-avatar.png", style: {normal: '120x120'}
  validates_attachment_content_type :image, content_type: %w(image/jpg image/jpeg image/png)

  after_destroy :remove_written_prices
  default_scope -> {asc :position}

  def remove_written_prices
    LanguagesGroup.all.each do |group|
      group.written_prices.each do |price|
        price.remove if price.written_type_id == self.id
      end
    end
  end
end