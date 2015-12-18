require 'rails_helper'

describe CloseVerbalJob, type: :job do

  describe '#perform' do

    let(:order) {create :order_verbal}

    subject{CloseVerbalJob.new.perform order.id.to_s, 'close'}

    it do
      expect_any_instance_of(Order::Verbal).to receive 'close'
      subject
    end

  end

end