class Order::Written::WorkReport
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Paperclip

  field :hours, type: Integer
  field :description, type: String

  belongs_to :translator, class_name: 'Profile::Translator'
  embedded_in :order_written, class_name: 'Order::Written'

  validates_presence_of :description, :file

  has_mongoid_attached_file :file
  do_not_validate_attachment_file_type :file
end
