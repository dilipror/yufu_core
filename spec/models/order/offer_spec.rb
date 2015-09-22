require 'rails_helper'

RSpec.describe Order::Offer, :type => :model do

  describe 'notifications' do
    describe 'after confirm' do
      subject{offer.update! is_confirmed: true}

      context 'offer is secondary' do
        let(:offer){create :order_offer, status: 'secondary'}

        it {expect{subject}.to change{offer.translator.user.notifications.count}.by(1)}
        it {expect{subject}.to change{offer.order.owner.user.notifications.count}.by(1)}
        it {expect{subject}.to change{NotificationMailer.deliveries.count}.by(3)}
      end

      context 'offer is primary' do
        let(:offer){create :order_offer, status: 'primary'}

        it {expect{subject}.to change{offer.translator.user.notifications.count}.by(1)}
        it {expect{subject}.to change{offer.order.owner.user.notifications.count}.by(1)}
        it {expect{subject}.to change{NotificationMailer.deliveries.count}}
      end
    end
  end

  describe '#process_order' do
    let(:order){create :wait_offers_order, offers: []}
    subject {create :order_offer, status: status, is_confirmed: confirm, order: order}

    context 'create primary offer' do
      let(:status){'primary'}

      context 'create confirmed offer' do
        let(:confirm){true}

        context 'order has confirmed secondary offer' do
          before :each do
            create :order_offer, status: 'secondary', is_confirmed: true, order: order
          end

          it{expect{subject}.to change{order.state}.to('in_progress')}
        end

        context 'order has not confirmed secondary offer' do
          it{expect{subject}.not_to change{order.state}}
        end
      end
      context 'create not confirmed offer' do
        let(:confirm){false}

        it{expect{subject}.not_to change{order.state}}
      end
    end

    context 'create secondary offer' do
      let(:status){'secondary'}

      context 'create confirmed offer' do
        let(:confirm){true}

        context 'order has confirmed primary offer' do
          before :each do
            create :order_offer, status: 'primary', is_confirmed: true, order: order
          end

          it{expect{subject}.to change{order.state}.to('in_progress')}
        end

        context 'order has not confirmed primary offer' do
          it{expect{subject}.not_to change{order.state}}
        end
      end
      context 'create not confirmed offer' do
        let(:confirm){false}

        it{expect{subject}.not_to change{order.state}}
      end
    end
  end

  specify 'cannot create 2 primary application for one order' do
    order = create :order_verbal
    order.offers << (create :order_offer, status: 'primary')
    application = build :order_offer, status: 'primary', order: order
    expect(application.valid?).to be_falsey
  end

  describe 'validate no secondary before primary' do

    let(:order){create :order_verbal}
    subject{Order::Offer.new(order: order, status: 'secondary').valid?}

    context 'no primary offer' do
      it {is_expected.to be_truthy}
    end

    context 'has primary offer' do

      before(:each) {create :order_offer, order: order, status: 'primary' }

      it {is_expected.to be_truthy}
    end
  end

  describe '#confirm' do

    let(:order){create :order_verbal, offers: [], state: 'wait_offer'}
    let(:offer){create :offer, order: order}
    before(:each){order.stub(:process).and_return(true)}

    subject{offer.confirm}

    context 'can confirm primary' do

      before(:each) do
        order.stub(:before_60).and_return(true)
        order.stub(:before_48).and_return(false)
        order.stub(:before_36).and_return(false)
        offer.stub(:primary?).and_return(true)
      end

      it{is_expected.to be_truthy}
      it{ expect{subject}.to change{offer.state}.from('new').to('confirmed')}
    end

    context 'can confirm backup' do

      before(:each) do
        order.stub(:before_60).and_return(true)
        order.stub(:before_48).and_return(true)
        order.stub(:before_36).and_return(false)
        offer.stub(:primary?).and_return(false)
        offer.stub(:back_up?).and_return(true)
      end

      it{is_expected.to be_truthy}
      it{expect{subject}.to change{offer.state}.from('new').to('confirmed')}
    end

    context 'can not confirm primary' do

      before(:each) do
        order.stub(:before_60).and_return(false)
        order.stub(:before_48).and_return(false)
        order.stub(:before_36).and_return(false)
        offer.stub(:primary?).and_return(true)
        offer.stub(:back_up?).and_return(false)
      end

      it{is_expected.to be_falsey}
      it{ expect{subject}.not_to change{offer.state}.from('new')}
    end

    context 'can not confirm backup' do

      before(:each) do
        order.stub(:before_60).and_return(true)
        order.stub(:before_48).and_return(false)
        order.stub(:before_36).and_return(false)
        offer.stub(:primary?).and_return(false)
        offer.stub(:back_up?).and_return(true)
      end

      it{is_expected.to be_falsey}
      it{ expect{subject}.not_to change{offer.state}.from('new')}
    end

    context 'can confirm any' do
      before(:each) do
        order.stub(:before_60).and_return(true)
        order.stub(:before_48).and_return(true)
        order.stub(:before_36).and_return(true)
        offer.stub(:primary?).and_return(false)
        offer.stub(:back_up?).and_return(false)
      end

      it{is_expected.to be_truthy}
      it{ expect{subject}.to change{offer.state}.from('new').to('confirmed')}
    end


  end

  describe '#primary?, #backup?' do

  end

end