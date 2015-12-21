require 'rails_helper'

RSpec.describe Order::LocalExpert, :type => :model do

  describe '#paid' do
    let(:order) {create :order_local_expert, state: 'new'}
    subject{order.paid_expert}

    it{expect{subject}.to change{order.state}.to 'in_progress'}

  end

  describe '#reject' do
    let(:order) {create :order_local_expert, state: 'wait_offer'}
    subject{order.cancel_by_client}

    it{expect{subject}.to change{order.state}.to 'canceled_by_client'}
    it{expect{subject}.to change{order.owner.user.notifications.count}.by 1}

  end

  describe '#close' do
    let!(:invoice) {create :invoice, subject: order}
    let(:order) {create :order_local_expert, state: 'in_progress'}
    subject{order.close}

    it{expect{subject}.to change{order.state}.to 'close'}
    it{expect{subject}.to change{order.owner.user.notifications.count}.by 1}
  end

  describe '#original_price' do
    let(:srv_ord1) {build :local_expert_service_order}
    let(:srv_ord2) {build :local_expert_service_order}
    let(:order) {create :order_local_expert, service_orders: [srv_ord1, srv_ord2]}


    subject{order.original_price}

    it{is_expected.to be_a BigDecimal}
    it{is_expected.to eq srv_ord1.cost + srv_ord2.cost}
  end

  describe 'paying_items' do

    subject{order.paying_items}

    let(:service_one){create :local_expert_service, name: 'serv one', cost: 10}
    let(:service_two){create :local_expert_service, name: 'serv two', cost: 10}

    let(:order){create :order_local_expert, service_orders: [(build :local_expert_service_order, service: service_one, count: 2),
                                                             (build :local_expert_service_order, service: service_two, count: 3)]}

    it ('count') {expect(subject.count).to eq(2)}
    it ('first cost') {expect(subject[0][:cost]).to eq(20)}
    it ('desc first') {expect(subject[0][:description]).to eq('serv one X 2')}
    it ('second cost') {expect(subject[1][:cost]).to eq(30)}
  end
end