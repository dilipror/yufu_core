module Order
  class LocalExpert < Base

    before_save :add_req_data, :set_private

    belongs_to :services_pack, :class_name => 'Order::ServicesPack'
    # has_many :tickets, class_name: 'Support::Ticket'
    # has_and_belongs_to_many :services, :class_name => 'Order::Service'
    embeds_many :service_orders, class_name: 'Order::ServiceOrder'
    embeds_one :required_data, :class_name => 'Order::RequiredData::Base'

    accepts_nested_attributes_for :required_data, :service_orders

    validates_presence_of :services_pack

    delegate :name, to: :services_pack, prefix: true

    has_notification_about :finish,
                           observers: :owner,
                           message: 'notifications.done_order',
                           mailer: ->(user, order) do
                             NotificationMailer.order_completed_8 user
                           end

    state_machine initial: :new do

      state :in_progress
      state :close

      event :paid_expert do
        transition [:new] => :in_progress
      end

      before_transition on: [:cancel_not_paid, :cancel_by_client, :cancel_by_yufu] do |order|
        order.notify_about_cancel_by_owner
      end

      before_transition on: :close do |order|
        order.notify_about_finish
      end
    end


    def original_price
      BigDecimal.new (service_orders.inject(0) {|sum, service_order| service_order.cost + sum }*100).round(2) / 100, 2
    end

    private
    def can_update?
      true
    end

    def set_private
      self.is_private = true
    end

    def add_req_data
      if self.required_data.blank? && !services_pack.req_data_class_name.blank?
        self.required_data = services_pack.req_data_class_name.constantize.new
      end
    end

    def create_invoice
      self.invoices.create! user: owner.try(:user), state: 'pending'
    end

    def paying_items
      res = []
      service_orders.each do |so|
        res << {cost: so.cost, description: "#{so.service.name} X #{so.count}"}
      end
      res
    end

  end
end