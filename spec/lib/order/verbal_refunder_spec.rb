require 'rails_helper'

RSpec.describe Order::VerbalRefunder do
  let(:order){create :order_verbal}
  let(:refunder){Order::VerbalRefunder.new(order)}

  describe '#calculate_sum' do
    subject{refunder.calculate_sum cancel_by}

    before(:each) {allow(refunder).to receive(:cost).and_return(100)}

    context 'cancel by yufu' do
      let(:cancel_by){:yufu}

      context 'order will begin less than 4 hours' do
        before(:each){allow(order).to receive(:will_begin_less_than?).with(4.hours).and_return(true)}

        it{is_expected.to eq 100 + 192}
      end

    end
  end

end