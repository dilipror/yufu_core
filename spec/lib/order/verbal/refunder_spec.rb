require 'rails_helper'

RSpec.describe Order::Verbal::Refunder do
  let(:order){create :order_verbal}
  let(:refunder){Order::Verbal::Refunder.new(order)}

  describe '#calculate_sum' do
    subject{refunder.calculate_sum cancel_by}

    before(:each) {allow(refunder).to receive(:cost).and_return(100)}

    context 'cancel by yufu' do
      let(:cancel_by){:yufu}

      before :each do
        allow(reunder).to recive
      end
    end
  end

end