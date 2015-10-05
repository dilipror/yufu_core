class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include Monetizeable
  include Filterable

  extend Enumerize

  CLIENT_INFO_ATTRIBUTES = ['first_name', 'last_name', 'email', 'phone', 'identification_number', 'skype', 'viber', 'wechat',
                            'company_name', 'company_uid', 'company_address']

  field :cost, type: BigDecimal
  field :state
  field :is_paid, default: false
  field :description
  field :need_invoice_copy, type: Boolean, default: false
  field :company_name
  field :company_uid
  field :company_address

  field :first_name
  field :last_name
  field :email
  field :phone
  field :identification_number
  field :skype
  field :viber
  field :wechat

  auto_increment :number

  belongs_to :country
  belongs_to :subject,  class_name: 'Order::Base'
  belongs_to :user
  belongs_to :pay_company, class_name: 'Company'
  belongs_to :pay_way, class_name: 'Gateway::PaymentGateway'

  has_many :transactions
  has_many :payments, class_name: 'Order::Payment'

  has_and_belongs_to_many :taxes

  embeds_many :items, class_name: 'Invoice::Item', cascade_callbacks: true
  accepts_nested_attributes_for :items

  # validates_presence_of :description

  monetize :cost
  # enumerize :pay_way, in: [:bank, :alipay, :local_balance, :credit_card, :paypal]

  # TODO need use build_client_info
  before_create :build_client_info_attributes
  after_create :pending_invoice
  after_save :update_taxes, :check_pay_way#, :pending_invoice

  after_save :append_profile, if: -> {subject.try(:owner).present?}

  #
  # validates_presence_of :wechat
  validates_presence_of :company_name, :company_uid, :company_address, if: -> {company_name.present? || company_uid.present? || company_address.present?}
  validate :uniq_phone, if: -> {new? && persisted? && phone.present?}
  validates_presence_of :first_name, :last_name, :identification_number, if: -> {new? && persisted?}

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
      # cost = invoice.cost.to_f
      # cost = invoice.exchanged_cost(invoice.pay_company.currency.iso_code).to_f if invoice.pay_way.gateway_type == :paypal
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


  def uniq_phone
    if phone?
      tmp = User.where phone: phone
      if tmp.count > 1 || (tmp.count == 1 && tmp.first != user )
        errors.add(:phone, 'phone already taken')
      end
    end
  end

  def encrypt_for_paypal(values)
    paypal_cert_rem = File.read("#{Rails.root}/certs/paypal_cert_sandbox.pem")
    app_cert_pem = File.read("#{Rails.root}/certs/app_cert.pem")
    app_key_pem = File.read("#{Rails.root}/certs/app_key.pem")
    signed = OpenSSL::PKCS7::sign(OpenSSL::X509::Certificate.new(app_cert_pem), OpenSSL::PKey::RSA.new(app_key_pem, ''),
                                  values.map { |k, v| "#{k}=#{v}" }.join("\n"), [], OpenSSL::PKCS7::BINARY)
    OpenSSL::PKCS7::encrypt([OpenSSL::X509::Certificate.new(paypal_cert_rem)], signed.to_der, OpenSSL::Cipher::Cipher::new("DES3"),
                            OpenSSL::PKCS7::BINARY).to_s.gsub("\n", "")
  end

  def paypal_encrypted
    paypal_gw_id = Gateway::PaymentGateway.find_by(gateway_type: :paypal).id
    values = {
        cmd: '_xclick',
        charset: 'utf-8',
        business: Rails.application.config.merchant_email,
        return: "#{Rails.application.config.success_root_url}/payment-gateway/#{paypal_gw_id}/success",
        cancel_return: '/',
        item_number: id,
        item_name: I18n.t('mongoid.paypal.interpretation_service'),
        currency_code: 'GBP',
        cert_id: Rails.application.config.cert_id,
        custom: Rails.application.config.custom,
        amount: exchanged_cost('GBP').round(2),
        notify_url: Rails.application.config.notify_url}
    encrypt_for_paypal(values)
  end

  # TODO: move this logic to gateway
  def check_pay_way
    if pay_way.present?
      if pay_way.gateway_type == 'bank'
        if paying?
          send_to_mail
          payments.create gateway_class: 'Order::Gateway::Bank', sum: cost, pay_way: pay_way, order: subject
        end
      else
        if paid?
          send_to_mail
        end
      end
    end
  end

  def send_to_mail
    PaymentsMailer.send_billing_info(user, self).deliver
  end

  def pending_invoice
    if subject.is_a?(Order::LocalExpert) && state == 'new'
      self.pending
    end
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
    if country.present? && pay_company.present? && pay_way.present?
      write_attribute :taxes, nil
      # taxes.delete_all
      get_taxes.each do |tax|
        tmp = Tax.find tax
        taxes << tmp
      end
    end
  end

  def get_taxes(country_id = country.id, company_id = pay_company.id, payway_id = pay_way.id, need_copy = need_invoice_copy)#, company_id, payment_gateway_id, need_copy)
    # cntr_id = country_id ||
    copy_tax = []
    if (need_copy == 'true' || need_copy == true)# && Company.find(company_id).currency.iso_code == 'CNY'
      copy_tax = Tax.where(original_is_needed: true, company_id: company_id, ).distinct(:id)
    end

    payway = Gateway::PaymentGateway.find(payway_id).taxes.distinct :id
    comp = Tax.where(company_id: company_id, original_is_needed: false).distinct :id
    cntr = Country.find(country_id).taxes.distinct :id

    comp & cntr & payway | copy_tax & payway & cntr
  end

  def humanize_float(amount)
    res = ""
    tmp = amount.to_s.split('.')
    res += tmp[0].to_i.humanize
    if tmp[1].present?
      res += ' and '
      res += tmp[1].to_i.humanize
    end
    res.capitalize
  end

  def client_name
    "#{first_name} #{last_name}"
  end

  def append_profile
    append_profile_field :first_name
    append_profile_field :last_name
    append_profile_field :phone
    append_profile_field :company_name
    append_profile_field :company_uid
    append_profile_field :company_address
    append_profile_field :identification_number
    append_profile_field :skype
    append_profile_field :viber
    append_profile_field :wechat

    unless country.nil?
      vl = self.country.id
      subject.owner.update_attribute :country, vl if subject.owner.send(:country).nil? || vl.present?
    end
    subject.owner.save validate: false
  end

  def append_profile_field(field)
    value =  self.try field
    subject.owner.update_attribute field, value if subject.owner.send(field).nil? || value.present?
  end

  def build_client_info_attributes
    CLIENT_INFO_ATTRIBUTES.each do |attr|
      eval("def #{attr}();return read_attribute(:#{attr}).present? ? read_attribute(:#{attr}) : subject.try(:owner).try(:#{attr});end;")
    end
    eval("def country_id;read_attribute(:country).present? ? read_attribute(:country) : subject.try(:owner).try(:country).try(:id);end;")
  end


end
