require 'rails_helper'

RSpec.describe Order::Commission, :type => :model do

  describe '.execute_transaction' do
    let(:debit){create :user, balance: 10000}
    let(:credit){create :user}
    let(:order){create :order_base}

    subject{Order::Commission.execute_transaction(:to_partner, debit, credit, 100, order)}

    context 'commission exists' do

      before(:each){create :order_commission, key: :to_partner, percent: 0.1}

      it('new transaction') {expect{subject}.to change{Transaction.count}.by(1)}
      it('has transition') {expect{subject}.to change{Transaction.last.try(:is_commission_from)}.to(Order::Commission.last)}
      it('money out of debit') {expect{subject}.to change{debit.balance}.by(-10)}
      it('money to credit') {expect{subject}.to change{credit.balance}.by(10)}
      it('return true') {expect(subject).to eq(true)}
    end

    context 'commission does not exists' do
      it {expect(subject).to eq(false)}
    end

  end

end
