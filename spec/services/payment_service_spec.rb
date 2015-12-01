require 'rails_helper'

describe PaymentService do
  let(:service){PaymentService.new(payment)}

  describe '#pay' do
    subject{service.pay! 100}
    let(:invoice) {payment.invoice}

    before(:each) do
      allow(invoice).to receive(:paid).and_return(true)
    end

    context 'payment in paying state' do
      let(:payment){create :payment}

      context 'sum of payment gte sum of invoice' do
        before(:each){allow(invoice).to receive(:cost).and_return(50)}

        it{expect{subject}.to change{payment.state}.to 'paid'}
        it{is_expected.to be_truthy}
        it{expect{subject}.to change{payment.crediting_funds}.by 100}

        it "credited to the user's account" do
          expect{subject}.to change{invoice.user.balance}.by(100)
        end

        it 'paid invoice' do
          expect(invoice).to receive(:paid).once
          subject
        end
      end

      context 'sum of payment lt sum of invoice' do
        before(:each){allow(invoice).to receive(:cost).and_return(200)}

        it{expect{subject}.to change{payment.state}.to 'partial_paid'}
        it{is_expected.to be_truthy}
        it{expect{subject}.to change{payment.crediting_funds}.by 100}

        it "credited to the user's account" do
          expect{subject}.to change{invoice.user.balance}.by(100)
        end

        it 'paid invoice' do
          expect(invoice).not_to receive(:paid)
          subject
        end
      end


    end

    context 'payment in other state state' do
      let(:payment){create :payment, state: :paid}

      it{expect{subject}.not_to change{payment.state}}

      it{is_expected.to be_falsey}

      it "credited to the user's account" do
        expect{subject}.not_to change{invoice.user.balance}
      end

      it 'paid invoice' do
        expect(invoice).not_to receive(:paid)
        subject
      end
    end
  end
end