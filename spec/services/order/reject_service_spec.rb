require 'rails_helper'

RSpec.describe Order::RejectService do
  let(:order){create :order_base}
  let(:service){Order::RejectService.new(order)}

  describe '#refund' do
    let(:owner){order.owner.user}
    let(:order){create :order_base, state: 'wait_offer'}

    subject{service.refund}

    context 'sum > 0' do
      before(:each){allow(service).to receive(:calculate_sum).and_return(100)}

      it{expect{subject}.to change{Transaction.count}.by 1}
      it{expect{subject}.to change{owner.reload.balance}.by(100)}
    end

    context 'sum <= 0' do
      before(:each){allow(service).to receive(:calculate_sum).and_return(0)}

      it{expect{subject}.not_to change{Transaction.count}}
      it{expect{subject}.not_to change{owner.reload.balance}}
    end
  end

  describe '#reject_order' do
    subject{service.reject_order}
    before(:each){allow(service).to receive(:refund)}

    it{expect{subject}.to change{order.state}.to 'canceled_by_client'}

    it 'receive refund method' do
      subject
      expect(service).to have_received(:refund)
    end
  end

end