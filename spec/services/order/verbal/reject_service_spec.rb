require 'rails_helper'

RSpec.describe Order::Verbal::RejectService do
  let(:order){create :order_verbal}
  let(:service){Order::Verbal::RejectService.new(order)}

  describe '#calculate_sum' do
    subject{service.calculate_sum cancel_by}

    before(:each) {allow(service).to receive(:cost).and_return(100)}

    context 'order canceled by yufu' do
      let(:cancel_by){:yufu}

      context 'order will begin less than 4 hours' do
        before(:each){allow(order).to receive(:will_begin_less_than?).with(4.hours).and_return(true)}

        it{is_expected.to eq 100 + 192}
      end
    end

    context 'order canceled by client' do
      let(:cancel_by){:client}
      context 'no offer' do
        before(:each){allow(order).to receive(:has_offer?).and_return false}

        context 'order paid less then 24 hours ago' do
          before(:each){allow(order).to receive(:paid_ago?).and_return false}

          it{is_expected.to eq 100}
        end

        context 'order paid more then 24 hours ago' do
          before(:each){allow(order).to receive(:paid_ago?).and_return true}
          it{is_expected.to eq 100 + 192}
        end
      end

      context 'order has offer' do
        before(:each){allow(order).to receive(:has_offer?).and_return true}

        context 'order is in progress' do
          before(:each){allow(order).to receive(:in_progress?).and_return true}

          it{is_expected.to eq 0}
        end

        context 'order is not in progress' do
          before(:each){allow(order).to receive(:in_progress?).and_return false}

          context 'order will begin less than 14 days' do
            before(:each){allow(order).to receive(:will_begin_less_than?).with(7.days).and_return false}
            before(:each){allow(order).to receive(:will_begin_at?).with(7.days).and_return false}
            before(:each){allow(order).to receive(:will_begin_less_than?).with(14.days).and_return true}
            before(:each){allow(order.language).to receive(:verbal_price).and_return 1}

            it{is_expected.to eq 100 - 8}
          end

          context 'order will begin less than 7 days' do
            before(:each){allow(order).to receive(:will_begin_less_than?).with(7.days).and_return true}
            before(:each){allow(order).to receive(:will_begin_at?).with(7.days).and_return false}
            before(:each){allow(order).to receive(:will_begin_less_than?).with(14.days).and_return false}

            it{is_expected.to eq 0}
          end

          context 'order will begin at 7 day' do
            before(:each){allow(order).to receive(:will_begin_less_than?).with(7.days).and_return false}
            before(:each){allow(order).to receive(:will_begin_at?).with(7.days).and_return true}
            before(:each){allow(order).to receive(:will_begin_less_than?).with(14.days).and_return false}


            context "order's hals cost less than 1 day price" do
              before(:each){allow(order.language).to receive(:verbal_price).and_return 1}
              it{is_expected.to eq 50}
            end

            context "order's half cost more than 1 day price" do
              before(:each){allow(order.language).to receive(:verbal_price).and_return 10}
              it{is_expected.to eq 20}
            end


          end
        end

      end
    end
  end


end