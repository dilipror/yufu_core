require 'rails_helper'

RSpec.describe Order::Payment, :type => :model do

  describe '#difference_to_user' do
    let(:invoice) {create :invoice}
    let(:payment) {Order::Payment.create sum: 300, partial_sum: 400,
                                    invoice: invoice}
    subject{payment.difference_to_user}

    it 'user balance should change' do
      expect{subject}.to change{payment.invoice.user.reload.balance}.from(0).to(100)
    end
  end

  describe '#partial_pay' do
    let(:order) {create :order_verbal}
    let(:invoice) {create :invoice, subject: order}
    let(:payment) {Order::Payment.create sum: 300, partial_sum: 0.0, invoice: invoice, order: order}

    subject{payment.partial_pay 100}

    it 'should change state' do
      expect{subject}.to change{payment.state}.from('paying').to('partial_paid')
    end

    it 'should change partial sum' do
      expect{subject}.to change{payment.partial_sum}.from(0.0).to(100)
    end

    context 'when partial_pay > sum' do
      subject{payment.partial_pay 400}

      it 'should change state' do
        expect{subject}.to change{payment.state}.from('paying').to('paid')
      end

    end
  end

end