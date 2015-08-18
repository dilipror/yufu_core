require 'rails_helper'

RSpec.describe Order::ServiceOrder, :type => :model do

  describe '#cost' do
    let(:service_pack) {create :service_pack}
    let(:order) {create :order_local_expert , services_pack: service_pack}
    let(:service_without_discount) {create :local_expert_service,
                                                     cost: 45,
                                                     discount: 0,
                                                     services_packs: [service_pack]}
    let(:service_with_discount) {create :local_expert_service,
                                           cost: 100,
                                           discount: 10,
                                           services_packs: [service_pack]}

    subject{service_order.cost}

    context 'when service without discount' do
      let(:service_order) {build :local_expert_service_order, service: service_without_discount, order_local_experts: order}

      it{is_expected.to eq 45}
    end

    context 'when service has discount' do
      let(:service_order) {build :local_expert_service_order, service: service_with_discount,
                                                               count: 2, order_local_experts: order}

      it{is_expected.to eq 190}
    end
  end

end