class Support::CommentReceipt
  include Mongoid::Document

  field :viewed, type: Mongoid::Boolean, default: false

  belongs_to :user
  belongs_to :comment, class_name: 'Support::Comment'

  scope :viewed, -> {where viewed: true}
  scope :unviewed, -> {where viewed: false}

  validates_uniqueness_of :user_id, scope: :comment_id
end
