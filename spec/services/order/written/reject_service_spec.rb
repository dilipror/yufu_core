require 'rails_helper'

RSpec.describe Order::Written::RejectService do
  let(:order){create :order_written}
  let(:service){Order::Written::RejectService.new(order)}

  describe '#calculate_sum' do
    subject{service.calculate_sum cancel_by}

    before(:each) {allow(service).to receive(:cost).and_return(100)}

    context 'order canceled by yufu' do
      let(:cancel_by){:yufu}

      it{is_expected.to eq 100}

    end

    context 'order canceled by client' do
      let(:cancel_by){:client}

      context 'order is in progress' do
        before(:each){order.update state: 'in_progress'}

        it{is_expected.to eq 0}
      end

      context 'order is not in progress' do

        context 'paid 7 days ago' do

          before(:each){allow(order).to receive(:paid_ago?).with(7.days).and_return(true)}

          it{is_expected.to eq 100+192}
        end

        context 'paid less than 7 days ago' do

          before(:each){allow(order).to receive(:paid_ago?).with(7.days).and_return(false)}

          it{is_expected.to eq 100}
        end
      end

    end
  end
end