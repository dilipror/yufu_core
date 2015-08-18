class Banner
  include Mongoid::Document
  include Mongoid::Paperclip
  include Mongoid::Timestamps
  include PromoObject

  include Rails.application.routes.url_helpers

  field :name

  has_many :transactions,  class_name: 'Transaction', as: :is_commission_from

  has_mongoid_attached_file :image, default_url: "/images/default_banner.jpg"
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/

  validates_presence_of :name

  before_save :set_image_extension

  def src
    ApplicationController.new.render_to_string(
        template: 'banners/item',
        locals: { :@banner => self },
        layout: false
    )
  end

  def url
    banner_url self
  end
  
  private
  def set_image_extension
    if self.image_content_type.nil? || self.image_file_name != 'data'
      return true
    end
    begin
      name = SecureRandom.uuid
    end while !User.where(image_file_name: name).empty?
    extension = self.image_content_type.gsub('image/', '.')
    self.image.instance_write(:file_name, name+extension)
  end
end
