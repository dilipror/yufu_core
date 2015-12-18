require 'rails_helper'

RSpec.describe Invoice, :type => :model do

  before(:each) do
    Currency.create iso_code: 'USD'
    Currency.create iso_code: 'CNY'
    Currency.create iso_code: 'EUR'
  end

  # TODO specs for client info attributs

  describe '#paying' do
    let(:order) {create :order_verbal}
    let(:invoice) {order.invoices.create user: create(:user)}
    let(:price) {order.original_price}

    subject{invoice.paying}

    before(:each) {invoice.update_attributes wechat: 'd'}

    it 'invoice is paying' do
      subject
      expect(invoice.state).to eq 'paying'
    end

    it 'invoice should have cost' do
      subject
      expect(invoice.read_attribute :cost).to eq price.to_s
    end
  end

  describe '#paid' do

    subject{invoice.paid}

    before(:each)do
      invoice =  order.invoices.create user: user
      invoice.update_attributes first_name: 'a', last_name: '3', email: 'dd3@ss.s'
      invoice.paying
      invoice.update cost: BigDecimal(100)
    end

    context 'client have enough money' do

      let(:user){create :user, balance: BigDecimal(1000)}
      let(:order){create :order_verbal, owner: user.profile_client, state: 'paying'}
      before(:each){Invoice.any_instance.stub(:cost).and_return(BigDecimal(100))}

      let(:invoice){order.invoices.first}

      it{expect{subject}.to change{invoice.reload.paid?}.to(true)}
      it{expect{subject}.to change{user.reload.balance}.by(BigDecimal(-100))}
      it{expect{subject}.to change{Office.head.reload.balance}.by(BigDecimal(100))}
      it{expect{subject}.to change{order.reload.paid?}.to(true)}
    end

    context 'client have not enought money' do
      let(:user){create :user, balance: 1}
      let(:order){create :order_verbal, owner: user.profile_client, state: 'paying'}
      let(:invoice){order.invoices.last}

      it{expect{subject}.not_to change{invoice.reload.state}}
    end

    context 'order is rejected' do
      let(:user){create :user, balance: 10000}
      let(:order){create :order_verbal, owner: user.profile_client, state: 'rejected'}
      let(:invoice){order.invoices.last}

      it{expect{subject}.not_to change{invoice.reload.paid?}}
      it{expect{subject}.not_to change{user.reload.balance}}
      it{expect{subject}.not_to change{Office.head.reload}}
      it{expect{subject}.not_to change{order.reload.paid?}}

    end
  end

  describe '#check_pay_way' do
    let(:bank) {create :payment_bank}
    let(:local) {create :payment_local_balance}
    subject{invoice}

    context 'when pay way is not bank' do
      let(:invoice) {create :invoice, state: 'paying', pay_way: local}
      it 'count payments not changed' do
        expect(invoice.payments.count).to eq 0
      end
    end

    context 'when pay way is bank' do
      let(:invoice) {create :invoice, state: 'paying', pay_way: bank, cost: 10}
      it 'count payments is changed' do
        subject
        expect(invoice.payments.count).to eq 1
        expect(invoice.payments.last.sum).to eq invoice.cost
      end
    end
  end

  describe '#cost' do
    subject{invoice.cost}
    context 'invoice has invoice items' do
      let(:invoice){create :invoice, items: [(build :invoice_item)]}

      it{is_expected.to be_a BigDecimal}
      it{is_expected.to eq invoice.items.sum(:cost)}
    end
  end

  describe '#regenerate' do

    context 'no subject' do
      let(:invoice){create :invoice, items: [(build :invoice_item, cost: 1000, description: 'meth')]}

      subject{invoice.regenerate}

      it {expect{subject}.to change{invoice.items.count}.to 0}

    end

    context 'with subject' do

      subject{invoice.regenerate}

      let(:order){create :order_verbal}
      let(:invoice){create :invoice, items: [(build :invoice_item, cost: 1000, description: 'meth')], subject: order}

      before(:each) do
        order.stub(:paying_items).and_return [{cost: 100, description: 'Olololo'}, {cost: 2000, description: 'Olalala'}]
        invoice.update subject: order
      end

      it {expect{subject}.to change{invoice.items.count}.to 2}

    end
  end

  describe '#amount_tax' do
    let!(:cny) {Currency.create name: 'Chinese Yuan', iso_code: 'CNY', symbol: '¥'}
    let!(:gbp) {Currency.create name: 'Pound Sterling', iso_code: 'GBP', symbol: '£'}

    let(:gbp_company) {create :gbp_company, currency: Currency.find_by(iso_code: 'GBP')}
    let(:cny_company) {create :cny_company, currency: Currency.find_by(iso_code: 'CNY')}

    let(:bank) {create(:payment_bank)}
    let(:local_balance) {create(:payment_local_balance)}

    let!(:tax_gbp1) {create :tax_uk_vat, company: gbp_company, payment_gateways: [bank, local_balance]}
    let!(:tax_gbp2) {create :tax_busness, company: gbp_company, payment_gateways: [bank, local_balance]}
    let!(:tax_cny1) {create :tax_add_surch, company: cny_company, payment_gateways: [bank]}
    let!(:tax_cny2) {create :tax_add_bus_tax, company: cny_company, payment_gateways: [bank, local_balance]}

    # before(:each) {invoice.update_attributes wechat: 'd', phone: '23111'}

    subject{invoice.amount_tax}

    context 'when no one tax' do
      let(:invoice){create :invoice, items: [(build :invoice_item, cost: 1000, description: 'meth')]}

      it{is_expected.to eq 0}
    end

    context 'when there are UK VAT tax' do
      let!(:country) {create :country, taxes: [tax_gbp1]}
      let(:order_verbal) {create :order_verbal}
      let(:invoice){create :invoice, items: [(build :invoice_item, cost: 1000, description: 'meth')],
                           pay_company: tax_gbp1.company, pay_way: tax_gbp1.payment_gateways.first,
                           subject: order_verbal}
      before :each do
        invoice.update_attributes country: country
        invoice.save
      end

      it{is_expected.to eq 200}
    end

    context 'when there are Busness tax' do
      let!(:country) {create :country, taxes: [tax_gbp2]}
      let(:order_verbal) {create :order_verbal}
      let(:invoice){create :invoice, items: [(build :invoice_item, cost: 1000, description: 'meth')],
                           pay_company: tax_gbp2.company, pay_way: tax_gbp2.payment_gateways.first,
                           subject: order_verbal}
      before :each do
        invoice.update_attributes country: country
        invoice.save
      end

      it{is_expected.to eq 100}
    end

    context 'when there are Additional tax surcharge' do
      let!(:country) {create :country, taxes: [tax_cny1]}
      let(:order_verbal) {create :order_verbal}
      let(:invoice){create :invoice, items: [(build :invoice_item, cost: 1000, description: 'meth')],
                           pay_company: tax_cny1.company, pay_way: tax_cny1.payment_gateways.first,
                           subject: order_verbal}
      before :each do
        invoice.pay_way.taxes << tax_cny1
        invoice.update_attributes country: country
        invoice.save
      end

      it{is_expected.to eq 100}
    end

    context 'when there are Additional business tax' do
      let!(:country) {create :country, taxes: [tax_cny2]}
      let(:order_verbal) {create :order_verbal}
      let(:invoice){create :invoice, items: [(build :invoice_item, cost: 1000, description: 'meth')],
                           pay_company: tax_cny2.company, pay_way: tax_cny2.payment_gateways.last,
                           subject: order_verbal, need_invoice_copy: true}
      before :each do
        invoice.update_attributes country: country
        invoice.save
      end

      it{is_expected.to eq 30}
    end
  end

  describe 'company params validations' do

    let(:invoice){build :invoice, attrs}

    subject{invoice.valid?}

    context 'fields are empty' do

      let(:attrs){{company_name: nil, company_uid: nil, company_address: nil}}

      it{is_expected.to be_truthy}

    end

    context 'company name is empty' do

      let(:attrs){{company_name: nil, company_uid: '123', company_address: 'boulevard'}}

      it{is_expected.to be_falsey}

    end

    context 'company uid is empty' do

      let(:attrs){{company_name: 'qwerty', company_uid: nil, company_address: 'boulevard'}}

      it{is_expected.to be_falsey}

    end

    context 'company address is empty' do

      let(:attrs){{company_name: 'qwerty', company_uid: '1234', company_address: nil}}

      it{is_expected.to be_falsey}

    end

  end

end
