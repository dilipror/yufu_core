require 'rails_helper'
RSpec.describe CloseUnpaidJob, :type => :worker do
  describe '#perform' do

    subject{CloseUnpaidJob.new.perform(order.id.to_s)}

    context 'order verbal' do

      context 'order is paid' do

        let(:translator){create :profile_translator}
        let(:order){create :order_verbal, invoices: [(create :invoice)], assignee: translator, state: 'wait_offer'}

        it{expect{subject}.not_to change{order.reload.state}}
      end

      context 'order is not paid' do

        let(:translator){create :profile_translator}
        let(:order){create :order_verbal, invoices: [(create :invoice)], assignee: translator, state: 'paying'}

        it{expect{subject}.to change{order.reload.state}.to 'canceled_by_not_paid'}
      end

    end

    context 'order written' do

      context 'order is paid' do

        let(:order){create :order_written, state: 'wait_offer'}

        it{expect{subject}.not_to change{order.reload.state}}
      end

      context 'order is not paid' do

        let(:order){create :order_written, state: 'paying'}

        it{expect{subject}.to change{order.reload.state}.to 'canceled_by_not_paid'}

      end

    end
  end
end