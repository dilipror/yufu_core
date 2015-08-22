module Support
  class Ticket
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Autoinc
    include Notificable

    field :number, type: Integer
    field :subject
    field :text

    increments :number

    belongs_to :theme, class_name: 'Support::Theme'
    belongs_to :user, inverse_of: :my_tickets
    belongs_to :expert, class_name: 'User', inverse_of: :expert_tickets
    belongs_to :assigned_to, class_name: 'User', inverse_of: :assigned_tickets

    has_one :order, class_name: 'Order::Base'
    # belongs_to :local_expert, class_name: 'Order::LocalExpert'

    has_many :comments, class_name: 'Support::Comment', dependent: :destroy

    embeds_many :embedded_attachments, as: :attached, cascade_callbacks: true

    has_and_belongs_to_many :attachments, dependent: :destroy
    has_and_belongs_to_many :watchers, class_name: 'User', inverse_of: :watched_tickets

    accepts_nested_attributes_for :attachments, :comments, :embedded_attachments

    validates_presence_of :user, :theme, :subject

    has_notification_about :new_comment, observers: :watchers, message: 'notifications.tickets.new_comment'

    scope :opened, -> {where :state.in => [:open, :reopened]}
    scope :closed, -> {where state: :closed}
    scope :in_progress, -> {where state: :in_progress}
    scope :visible_for, -> (user) {any_of({user: user}, {assigned_to: user})}

    before_create :add_default_watchers
    before_save :add_assigned_to_watchers

    default_scope -> {desc :_id}

    state_machine initial: :open do
      state :in_progress
      state :closed
      state :replied

      state :delegated_to_expert
      state :expert_in_progress
      state :expert_replied

      event :processing do
        transition [:open, :reopened] => :in_progress
      end

      event :close do
        transition  [:open, :reopened, :in_progress] => :closed
      end

      event :reopen do
        transition :closed => :open
      end

      event :reply do
        transition [:open, :reopened, :in_progress] => :replied
      end

      event :delegate_to_expert do
        transition [:open, :in_progress] => :delegated_to_expert
      end

      event :expert_process do
        transition :delegated_to_expert => :expert_in_progress
      end

      event :expert_reply do
        transition :expert_in_progress => :expert_replied
      end
    end

    def processing(user)
      self.assigned_to = user
      super user
    end

    def expert_process(user)
      self.expert = user
      super user
    end

    def has_new_comments_for?(user)
      receipts_for(user).unviewed.exists?
    end

    def viewed_by!(user)
      receipts_for(user).unviewed.update_all viewed: true
    end

    def receipts_for(user)
      Support::CommentReceipt.where(user: user, :comment_id.in => comment_ids)
    end


    def human_state_name_for_client
      I18n.t "mongoid.state_machine_human_name.#{state}"
    end

    private
    def add_default_watchers
      watchers << user
      watchers << assigned_to
    end

    def add_assigned_to_watchers
      watchers << assigned_to if assigned_to.present? && !watchers.include?(assigned_to)
    end
  end
end
