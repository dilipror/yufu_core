require 'rails_helper'

RSpec.describe Invoice, :type => :model do

  before(:each) do
    Currency.create iso_code: 'USD'
    Currency.create iso_code: 'CNY'
    Currency.create iso_code: 'EUR'
  end

  describe 'build client info' do
    let(:order) {create :order_verbal}
    let(:invoice) {order.invoices.create cost: 100, user: create(:user)}

    subject{invoice}

    it 'expect client info' do
      subject
      expect(invoice.client_info).not_to be_nil
    end
  end

  describe '#paying' do
    let(:order) {create :order_verbal}
    let(:invoice) {order.invoices.create user: create(:user)}
    let(:price) {order.original_price}

    subject{invoice.paying}

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
  end

  describe '#check_pay_way' do
    subject{invoice}

    context 'when pay way is not bank' do
      let(:invoice) {create :invoice, state: 'paying', pay_way: :local_balance}
      it 'count payments not changed' do
        expect(invoice.payments.count).to eq 0
      end
    end

    context 'when pay way is bank' do
      let(:invoice) {create :invoice, state: 'paying', pay_way: :bank, cost: 10}
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

end
