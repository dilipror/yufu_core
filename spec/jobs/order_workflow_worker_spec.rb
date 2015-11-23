require 'rails_helper'

describe OrderWorkflowWorker, type: :worker do

  describe '#perform' do

    let(:order) {create :order_verbal}

    subject{OrderWorkflowWorker.new.perform order.id.to_s, 'after_12'}

    it do
      expect_any_instance_of(Order::Verbal::EventsService).to receive 'after_12'
      subject
    end

  end

end