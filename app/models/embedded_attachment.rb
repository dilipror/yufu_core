class EmbeddedAttachment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip


  has_mongoid_attached_file :file

  do_not_validate_attachment_file_type :file

  delegate :url, to: :file

  embedded_in :attached, polymorphic: true
  # accepts_nested_attributes_for :attached, allow_destroy: true
end