require 'rails_helper'

RSpec.describe Order::Base, :type => :model do

  describe '#after_close_cashflow' do

    before (:each) do
      Order::Commission.create key: :to_senior, percent: 0.03
      Order::Commission.create key: :to_partner, percent: 0.06
      Order::Commission.create key: :to_partners_agent, percent: 0.015
      Order::Commission.create key: :to_translators_agent, percent: 0.015
      Order::Commission.create key: :to_translator, percent: 0.7
    end

    let(:user){create :user}

    let(:assignee) {create :profile_translator}

    before(:each) {order.invoices.create cost: 100.0}

    subject{order.after_close_cashflow}

    context 'order has translator' do
      let(:order) {create :order_base, assignee: assignee}
      it {expect{subject}.to change{order.assignee.user.reload.balance}.by(BigDecimal.new 95*0.7, 4)}
    end

    context 'translator has overlord' do
      let(:overlord) {create :user}

      let(:translator) {create :user, overlord: overlord}
      let(:assignee) {create :profile_translator, user: translator}

      let(:order) {create :order_base, assignee: assignee}

      it {expect{subject}.to change{overlord.reload.balance}.by(BigDecimal.new 95*0.015, 4)}
    end

    context 'order has ref link' do
      let(:order){create :order_base, referral_link: user.referral_link}
      it {expect{subject}.to change{user.reload.balance}.by(BigDecimal.new 95*0.06, 2)}
    end

    context 'order has banner' do
      let(:order){create :order_base, banner: user.banners.first}
      it {expect{subject}.to change{user.reload.balance}.by(BigDecimal.new 95*0.06, 2)}
    end

    context 'partner has overlord' do
      let(:order){create :order_base, banner: user.banners.first}
      before(:each){user.update overlord: (create :user)}
      it {expect{subject}.to change{user.reload.balance}.by(BigDecimal.new 95*0.06, 2)}
    end

    context 'verbal has senior' do
      let(:senior){create :profile_translator}
      let(:language){create :language, senior: senior}
      let(:order){create :order_verbal, main_language_criterion: (create :order_language_criterion, language: language), is_private: false}

      it {expect{subject}.to change{senior.user.reload.balance}.by(BigDecimal.new 95*0.03, 4)}

    end

    context 'written has senior' do

      let(:senior){create :profile_translator}
      let(:language){create :language, senior: senior}
      let(:order){create :order_written}

      before(:each){order.stub(:real_translation_language).and_return(language)}

      it {expect{subject}.to change{senior.user.reload.balance}.by(BigDecimal.new 95*0.03, 4)}

    end

    context 'order is private' do

      let(:senior){create :user}
      let(:translator){create :profile_translator}
      let(:language){create :language, senior: senior}
      let(:order){create :order_written, is_private: true, assignee: translator}

      before(:each){order.stub(:real_translation_language).and_return(language)}

      it {expect{subject}.not_to change{senior.reload.balance}}
      it {expect{subject}.not_to change{translator.user.reload.balance}}

    end
  end

  describe '#paid' do
    let(:user){create :user}
    let(:order){create :order_verbal, referral_link: user.referral_link}

    let(:time){ Time.now}

    before(:each) do
      order.invoices.create! cost: 100.0
      time
      Time.stub(:now).and_return(time)
    end
    # before(:each) {order.invoices.last.update_attributes wechat: 'd', phone: '22342'}

    subject{order.paid}

    it{expect{subject}.to change{order.state}.to 'wait_offer'}
    it{expect{subject}.to change{order.paid_time}.to time}
  end

  describe '#set_owner!' do
    before(:each){order.invoices.create}

    let(:order) {create :order_base, owner: nil}
    subject{order.set_owner! user}

    context 'user has only client profile' do
      let(:user) {create :client}
      it "sets owner as user's client profile" do
        expect{subject}.to change{order.reload.owner}.to(user.profile_client)
      end
    end
  end

  describe 'closed' do
    let(:user) {create :user}
    let(:translator) {create :profile_translator}
    before(:each){order.invoices.create}
    let(:order) {create :order_base, assignee: translator, owner: user.profile_client, state: :in_progress}
    it 'expect notification' do
      expect{order.close}.to  change{ translator.user.notifications.count }.by(1)
    end

    it 'expect message' do
      order.close
      expect(translator.user.notifications.last.message).to eq('Order you assigned is closed')
    end
  end

  describe '#create and execute transaction' do

    let(:debit){create :user, balance: 10000}
    let(:credit){create :user}
    let(:order){create :order_base}

    context 'no commission' do
      subject{order.create_and_execute_transaction(debit, credit, 100)}

      it {expect{subject}.to change{Transaction.count}.by(1)}

      it {expect{subject}.not_to change{Transaction.last.try(:is_commission_from)}}

    end

    context 'with commission' do

      let(:commission){create :order_commission}

      subject{order.create_and_execute_transaction(debit, credit, 100, commission)}

      it {expect{subject}.to change{Transaction.count}.by(1)}

      it {expect{subject}.to change{Transaction.last.try(:is_commission_from)}.to(commission)}

    end
  end
end
