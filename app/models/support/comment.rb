module Support
  class Comment
    include Mongoid::Document
    include Mongoid::Timestamps

    field :text

    belongs_to :author, class_name: 'User'
    belongs_to :ticket, class_name: 'Support::Ticket'

    has_many :comment_receipts, class_name: 'Support::CommentReceipt', dependent: :destroy

    embeds_many :embedded_attachments, as: :attached, cascade_callbacks: true
    accepts_nested_attributes_for :embedded_attachments

    default_scope -> {asc :created_at}

    validates_presence_of :author, :ticket, :text

    after_create {ticket.notify_about_new_comment}
    after_create :create_comment_receipts

    def viewed_by?(user)
      comment_receipts.viewed.where(user: user).exists?
    end


    private
    def create_comment_receipts
      ticket.watchers << author unless ticket.watchers.include? author
      ticket.watchers.each do |u|
        comment_receipts.create user: u, viewed: u.eql?(author)
      end
    end
  end
end
