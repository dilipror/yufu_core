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

  describe 'validates in keys' do
    subject{Order::Commission.new(key: key, percent: 0.12).valid?}

    context 'valid' do
      let(:key){:to_translator}

      it{is_expected.to be_truthy}
    end

    context 'invalid' do
      let(:key){:to_vasya_pupking}

      it{is_expected.to be_falsey}
    end

  end

  describe '.create and execute transaction' do

    let(:debit){create :user, balance: 10000}
    let(:credit){create :user}
    let(:order){create :order_base}

    context 'no commission' do
      subject{Order::Commission.create_and_execute_transaction(debit, credit, 100, order)}

      it {expect{subject}.to change{Transaction.count}.by(1)}

      it {expect{subject}.not_to change{Transaction.last.try(:is_commission_from)}}

    end

    context 'with commission' do

      let(:commission){create :order_commission}

      subject{Order::Commission.create_and_execute_transaction(debit, credit, 100, order, commission)}

      it {expect{subject}.to change{Transaction.count}.by(1)}

      it {expect{subject}.to change{Transaction.last.try(:is_commission_from)}.to(commission)}

    end
  end

end
