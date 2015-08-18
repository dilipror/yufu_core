require 'rails_helper'

RSpec.describe Order::Base, :type => :model do

  describe '#after_close_cashflow' do
    let(:assignee) {create :profile_translator}

    before(:each) {order.invoices.create cost: 100.0}

    subject{order.after_close_cashflow}

    context 'order has translator' do

      let(:order) {create :order_base, assignee: assignee}
      it {expect{subject}.to change{order.assignee.user.reload.balance}.by(BigDecimal.new '30.0')}
    end

    context 'order has no translator' do

    end

    context 'translator has overlord' do
      let(:overlord) {create :user}

      let(:translator) {create :user, overlord: overlord}
      let(:assignee) {create :profile_translator, user: translator}

      let(:order) {create :order_base, assignee: assignee}

      it {expect{subject}.to change{overlord.reload.balance}.by(BigDecimal.new '3.0')}
    end

    context 'translator has no overlord' do

    end

  end

  describe '#after_paid_cashflow' do
    let(:user){create :user}

    before(:each) {order.invoices.create! cost: 100.0}

    subject{order.after_paid_cashflow}

    context 'order has ref link' do
      let(:order){create :order_base, referral_link: user.referral_link}
      it {expect{subject}.to change{user.reload.balance}.by(BigDecimal.new '3.0')}
    end

    context 'order has banner' do
      let(:order){create :order_base, banner: user.banners.first}
      it {expect{subject}.to change{user.reload.balance}.by(BigDecimal.new '3.0')}
    end

    context "order's owner has overlord" do
      let(:user){create :user, overlord: create(:user)}
      let(:order){create :order_base, owner: user.profile_client}
      it {expect{subject}.to change{user.reload.overlord.balance}.by(BigDecimal.new '3.0')}
    end
  end

  describe '#paid' do
    let(:user){create :user}
    let(:order){create :order_verbal, referral_link: user.referral_link}

    before(:each) {order.invoices.create! cost: 100.0}

    subject{order.paid}

    it{expect{subject}.to change{order.state}.to 'wait_offer'}

    context 'order has a referral link' do
      it 'charge commission to owner of the link' do
        expect{subject}.to change{user.reload.balance}.by(BigDecimal.new '3.0')
      end
    end
  end

  describe '#offer_status_for' do
    let(:offer) {create :order_offer}
    let(:order) {offer.order}

    it 'returns status of offer for prifile' do
      expect(order.offer_status_for offer.translator).to eq(offer.status)
    end

    it 'returns nil if offer is not exist' do
      expect(order.offer_status_for create(:profile_translator)).to eq(nil)
    end
  end


  describe '#can_send_primary_offer?' do
    it 'returns true if order has not primary offer' do
      order = create :order_verbal
      expect(order.can_send_primary_offer?).to be_truthy
    end
    it 'returns false if order has primary offer' do
      order = create :order_verbal
      order.offers << (create :order_offer, status: 'primary')
      expect(order.can_send_primary_offer?).to be_falsey
    end
  end

  describe '#reject' do
    let(:order) {create :order_base, assignee: (create :profile_translator), state: :in_progress}
    subject{order.reject}
    it 'sets state as wait_offer' do
      expect{subject}.to change{order.reload.wait_offer?}.to(true)
    end
    it 'sets assignee as nil' do
      expect{subject}.to change{order.reload.assignee}.to(nil)
    end
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
    let(:order) {create :order_base, assignee: translator, owner: user, state: :in_progress}
    it 'expect notification' do
      expect{order.close}.to  change{ translator.user.notifications.count }.by(1)
    end

    it 'expect message' do
      order.close
      expect(translator.user.notifications.last.message).to eq('Order you assigned is closed')
    end
  end

end
