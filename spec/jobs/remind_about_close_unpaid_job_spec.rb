require 'rails_helper'
RSpec.describe RemindAboutCloseUnpaidJob, :type => :worker do

  describe '#perform' do

    subject{RemindAboutCloseUnpaidJob.new.perform(order.id)}

    before(:each) do
      allow_any_instance_of(PaymentsMailer).to receive(:pdf_invoice).and_return(WickedPdf.new.pdf_from_string(''))
      order.invoices << Invoice.create(subject: order)
      order.save!(validate: false)
    end

    context 'state is new' do
      let(:order){create :order_base, state: 'new'}

      it{expect{subject}.to change{order.owner.user.reload.notifications.count}.by(1)}
    end

    context 'state is paying' do
      let(:order){create :order_base, state: 'paying'}

      it{expect{subject}.to change{order.owner.user.reload.notifications.count}.by(1)}
    end

    context 'other state' do
      let(:order){create :order_base, state: 'wait_offer'}

      it{expect{subject}.not_to change{order.owner.user.reload.notifications.count}}
    end
  end

end