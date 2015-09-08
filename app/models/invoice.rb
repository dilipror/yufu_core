class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include Monetizeable
  include Filterable

  extend Enumerize

  field :cost, type: BigDecimal
  # field :pay_way
  # field :pay_company
  field :state
  field :is_paid, default: false
  field :description
  field :need_invoice_copy, type: Boolean, default: false

  auto_increment :number

  belongs_to :subject,  class_name: 'Order::Base'
  belongs_to :user
  belongs_to :pay_company, class_name: 'Company'
  belongs_to :pay_way, class_name: 'Gateway::PaymentGateway'

  has_many :transactions
  has_many :payments, class_name: 'Order::Payment'

  has_and_belongs_to_many :taxes

  embeds_one :client_info, class_name: 'Order::ClientInfo', cascade_callbacks: true
  embeds_many :items, class_name: 'Invoice::Item', cascade_callbacks: true
  accepts_nested_attributes_for :client_info, :items

  # validates_presence_of :description

  monetize :cost
  # enumerize :pay_way, in: [:bank, :alipay, :local_balance, :credit_card, :paypal]

  # TODO need use build_client_info
  before_create :create_client_info
  # before_save :pending_invoice
  after_save :update_taxes, :check_pay_way#, :pending_invoice
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

  # filtering
  def self.filter_state(state)
    where state: state
  end

  def self.filter_email(email)
    user_ids = User.where(email: /.*#{email}.*/).distinct :id
    where :user_id.in => user_ids
  end

  def self.hack_mailer
    NotificationMailer.new_order_for_translator(User.first).deliver
  end

  def currency
    pay_company.try(:currency) || Currency.where(iso_code: Currency.current_currency).first
  end

  def check_pay_way
    if pay_way.present? && state == 'paying'
      PaymentsMailer.send_billing_info(user, self).deliver
      if pay_way.gateway_type == 'bank'
        payments.create gateway_class: 'Order::Gateway::Bank', sum: cost, pay_way: pay_way, order: subject
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

  def cost_without_taxes
    if items.empty?
      attr = read_attribute :cost
      result = attr || subject.try(:original_price) || '0.0'
      result.is_a?(BigDecimal) ? result : BigDecimal.new(result.to_s)
    else
      items.sum :cost
    end
  end

  def cost
    cost_without_taxes + amount_tax
  end

  def regenerate
    items.delete_all
    unless subject.nil?
      subject.paying_items.each do |it|
        items.create cost: it[:cost], description: it[:description]
      end
    end
  end

  def amount_tax(invoice_cost = nil)
    cost = cost_without_taxes
    amount_tax = 0
    taxes.each do |tax|
      amount_tax += cost * tax.tax / 100
    end
    amount_tax
  end

  def update_taxes
    if client_info.country.present? && pay_company.present? && pay_way.present?
      write_attribute :taxes, nil
      # taxes.delete_all
      get_taxes.each do |tax|
        tmp = Tax.find tax
        taxes << tmp
      end
    end
  end

  def get_taxes(country_id = client_info.country.id, company_id = pay_company.id, payway_id = pay_way.id, need_copy = need_invoice_copy)#, company_id, payment_gateway_id, need_copy)
    # cntr_id = country_id ||
    copy_tax = []
    if (need_copy == 'true' || need_copy == true) && Company.find(company_id).currency.iso_code == 'CNY'
      copy_tax << Tax.find_by(original_is_needed: true).id#.distinct(:id)
    end

    payway = Gateway::PaymentGateway.find(payway_id).taxes.distinct :id
    comp = Tax.where(company_id: company_id, original_is_needed: false).distinct :id
    cntr = Country.find(country_id).taxes.distinct :id

    comp & cntr & payway | copy_tax
  end

end
