class Support::CommentReceipt
  include Mongoid::Document

  field :viewed, type: Mongoid::Boolean, default: false

  belongs_to :user
  belongs_to :comment, class_name: 'Support::Comment'

  def self.viewed
    comment_ids = Support::Comment.where(is_public: true).distinct :id
    where viewed: true, :comment_id.in => comment_ids
  end

  def self.unviewed
    comment_ids = Support::Comment.where(is_public: true).distinct :id
    where viewed: false, :comment_id.in => comment_ids
  end
  # scope :viewed, -> {where viewed: true}
  # scope :unviewed, -> {where viewed: false}

  validates_uniqueness_of :user_id, scope: :comment_id
end
