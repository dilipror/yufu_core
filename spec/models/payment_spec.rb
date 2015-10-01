require 'rails_helper'

RSpec.describe Order::Payment, :type => :model do

  describe '#pay' do
    let(:bank) {create :payment_bank}
    let(:invoice) {create :invoice, state: 'paying', pay_way: bank, cost: 10}
    let(:payment) {invoice.payments.last}

    # before(:each) {invoice.client_info.update_attributes wechat: 's'}


    before(:each) do
      Currency.create iso_code: 'USD'
      Currency.create iso_code: 'CNY'
      Currency.create iso_code: 'EUR'
      invoice.update_attributes wechat: 's'
    end

    subject{payment.pay}

    it 'invoice should be paid' do
      subject
      expect(invoice.state).to eq 'paid'
      expect(payment.balance).to eq 0
      expect(payment.invoice.user.balance).to eq 0
    end
  end

end
