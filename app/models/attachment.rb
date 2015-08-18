class Attachment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip


  has_mongoid_attached_file :file

  do_not_validate_attachment_file_type :file

  delegate :url, to: :file
end