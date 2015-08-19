class Support::TicketSerializer < ActiveModel::Serializer
  attributes :id, :subject, :text, :comment_ids, :number, :theme_id, :human_state_name, :state, :has_new_comments,
             :assigned_to_id, :user_id, :order_id

  has_many :embedded_attachments

  def order_id
    @object.order.try :id
  end

  def has_new_comments
    @object.has_new_comments_for? @scope
  end

  def human_state_name
    @object.human_state_name_for_client
  end
end
