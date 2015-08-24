class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include Monetizeable
  extend Enumerize

  field :cost, type: BigDecimal
  # field :pay_way
  field :pay_company
  field :state
  field :is_paid, default: false
  field :description

  auto_increment :number

  belongs_to :subject,  class_name: 'Order::Base'
  belongs_to :user
  belongs_to :pay_way, class_name: 'Gateway::PaymentGateway'

  has_many :transactions
  has_many :payments, class_name: 'Order::Payment'

  embeds_one :client_info, class_name: 'Order::ClientInfo', cascade_callbacks: true
  embeds_many :items, class_name: 'Invoice::Item', cascade_callbacks: true
  accepts_nested_attributes_for :client_info, :items

  # validates_presence_of :description

  monetize :cost
  # enumerize :pay_way, in: [:bank, :alipay, :local_balance, :credit_card, :paypal]

  # TODO need use build_client_info
  before_create :create_client_info
  # before_save :pending_invoice
  after_save :check_pay_way#, :pending_invoice
  #
  # validates_presence_of :wechat
  

  state_machine initial: :new do
    state :pending
    state :new
    state :paying do
      validates_presence_of :user_id
    end
    state :paid

    before_transition :new => :paying do |invoice, transition|
      invoice.write_attribute :cost, invoice.subject.try(:original_price)
    end

    # before_transition :pending => :paying do |invoice, transition|
    #   invoice.write_attribute :cost, invoice.subject.try(:original_price)
    # end

    before_transition on: :paid do |invoice, transition|
      can_execute = invoice.user.balance.to_f >= invoice.cost.to_f
      if can_execute
        Transaction.create(sum: invoice.cost, debit: invoice.user, credit: Office.head, invoice: invoice).execute
        invoice.subject.try(:paid)
      end
      can_execute
    end

    event :pending do
      transition new: :pending
    end

    event :paying do
      transition :new => :paying
    end

    event :paid do
      transition paying: :paid
    end

    event :open do
      transition pending: :new
    end
  end

  def self.hack_mailer
    NotificationMailer.new_order_for_translator(User.first).deliver
  end

  def check_pay_way
    if pay_way.present? && state == 'paying'
      PaymentsMailer.send_billing_info(user, self).deliver
      if pay_way.gateway_type == 'bank'
        payments.create gateway_class: 'Order::Gateway::Bank', sum: cost, pay_way: pay_way
      end
    end
  end

  def pending_invoice
    if subject.is_a? Order::LocalExpert
      self.pending
    end
  end


  def create_client_info
    build_client_info
  end

  def cost
    if items.empty?
      attr = read_attribute :cost
      result = attr || subject.try(:original_price) || '0.0'
      result.is_a?(BigDecimal) ? result : BigDecimal.new(result.to_s)
    else
      items.sum :cost
    end
  end

  def regenerate
    items.delete_all
    unless subject.nil?
      subject.paying_items.each do |it|
        items.create cost: it[:cost], description: it[:description]
      end
    end
  end

end
