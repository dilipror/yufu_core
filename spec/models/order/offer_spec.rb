require 'rails_helper'

RSpec.descrie Order::Offer, :type => :model do


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

  describe '#can_confirm?' do

    let(:translator){create :profile_translator}

    let(:order){create :order_verbal, offers: [], state: 'wait_offer'}
    let(:offer){create :offer, order: order, translator: translator}
    before(:each){order.stub(:process).and_return(true)}

    subject{offer.confirm}

    context 'can confirm primary' do

      before(:each) do
        order.stub(:will_begin_less_than?).with(60.hours).and_return(true)
        order.stub(:will_begin_less_than?).with(48.hours).and_return(false)
        order.stub(:will_begin_less_than?).with(36.hours).and_return(false)
        offer.stub(:primary?).and_return(true)
      end

      it{is_expected.to be_truthy}
      it{ expect{subject}.to change{offer.state}.from('new').to('confirmed')}
    end

    context 'can confirm backup' do

      before(:each) do
        order.stub(:will_begin_less_than?).with(60.hours).and_return(true)
        order.stub(:will_begin_less_than?).with(48.hours).and_return(true)
        order.stub(:will_begin_less_than?).with(36.hours).and_return(false)
        offer.stub(:primary?).and_return(false)
        offer.stub(:back_up?).and_return(true)
      end

      it{is_expected.to be_truthy}
      it{expect{subject}.to change{offer.state}.from('new').to('confirmed')}
    end

    context 'can not confirm primary' do

      before(:each) do
        order.stub(:will_begin_less_than?).with(60.hours).and_return(false)
        order.stub(:will_begin_less_than?).with(48.hours).and_return(false)
        order.stub(:will_begin_less_than?).with(36.hours).and_return(false)
        offer.stub(:primary?).and_return(true)
        offer.stub(:back_up?).and_return(false)
      end

      it{is_expected.to be_falsey}
      it{ expect{subject}.not_to change{offer.state}.from('new')}
    end

    context 'can not confirm backup' do

      before(:each) do
        order.stub(:will_begin_less_than?).with(60.hours).and_return(true)
        order.stub(:will_begin_less_than?).with(48.hours).and_return(false)
        order.stub(:will_begin_less_than?).with(36.hours).and_return(false)
        offer.stub(:primary?).and_return(false)
        offer.stub(:back_up?).and_return(true)
      end

      it{is_expected.to be_falsey}
      it{ expect{subject}.not_to change{offer.state}.from('new')}
    end

    context 'can confirm any' do
      before(:each) do
        order.stub(:will_begin_less_than?).with(60.hours).and_return(true)
        order.stub(:will_begin_less_than?).with(48.hours).and_return(true)
        order.stub(:will_begin_less_than?).with(36.hours).and_return(true)
        offer.stub(:primary?).and_return(false)
        offer.stub(:back_up?).and_return(false)
      end

      it{is_expected.to be_truthy}
      it{ expect{subject}.to change{offer.state}.from('new').to('confirmed')}
    end


  end

  describe '#primary?, #backup?' do

  end

  describe 'become main or back_up' do

    let(:translator){create :profile_translator}

    subject{order.offers.create translator: translator}

    context 'main offer' do
      let(:order){create :order_verbal, offers: []}

      it{expect{subject}.to change{translator.user.notifications.count}.by(1)}
      it{expect{subject}.to change{order.owner.user.notifications.count}.by(1)}

    end

    context 'back_up offer' do
      let(:order){create :order_verbal, offers: []}

      before(:each){create :offer, translator: translator, order: order}

      let(:translator_back_up){create :profile_translator}

      subject{order.offers.create translator: translator_back_up}

      it{expect{subject}.not_to change{translator.user.notifications.count}}
      it{expect{subject}.to change{translator_back_up.user.notifications.count}.by(1)}
      it{expect{subject}.to change{order.owner.user.notifications.count}.by(1)}

    end
  end

  describe '#confirm' do

    let(:translator){create :profile_translator}
    let(:translator_bu){create :profile_translator}
    let(:translator_other){create :profile_translator}
    let(:order){create :order_verbal}
    let(:offer){create :offer, translator: translator, order: order}
    let(:offer_1){create :offer, translator: translator_bu, order: order}
    let(:offer_2){create :offer, translator: translator_other, order: order}

    subject{offer.confirm}

    context 'can confirm' do

      before(:each){offer.stub(:can_confirm?).and_return(true)}

      it{expect{subject}.to change{translator.user.reload.notifications.count}.by(1)}
      it{expect{subject}.not_to change{translator_bu.user.notifications.count}}
      it{expect{subject}.not_to change{translator_other.user.notifications.count}}

      context 're-confirmed be main' do

        before(:each){offer.stub(:can_confirm?).and_return(true)}

        it{expect{subject}.not_to change{order.owner.user.notifications.count}}

      end

      context 're-confirmed be main' do

        before(:each){offer.stub(:can_confirm?).and_return(true)}

        before(:each){
          offer
          offer_1
        }

        subject{offer.confirm}

        it{expect{subject}.not_to change{order.owner.user.notifications.count}}

      end

      context 're-confirmed other' do

        before(:each){offer.stub(:can_confirm?).and_return(true)}

        subject{offer_2.confirm}

        let(:offer){create :offer, translator: translator, order: order, state: 'rejected'}
        let(:offer_1){create :offer, translator: translator_bu, order: order, state: 'rejected'}


        before(:each){
          order.stub(:will_begin_less_than?).with(36.hours).and_return(true)
          order.stub(:process).and_return(true)
          order.stub(:before_60)
          offer
          offer_1
          offer_2
        }

        it{expect{subject}.to change{translator_other.user.notifications.count}.by(1)}
        it{expect{subject}.to change{order.owner.user.reload.notifications.count}.by(1)}
        it{expect{subject}.not_to change{translator.user.notifications.count}}
        it{expect{subject}.not_to change{translator_bu.user.notifications.count}}

      end

    end

    context 'can not confirm' do

      before(:each){offer.stub(:can_confirm?).and_return(false)}

      it{expect{subject}.not_to change{order.state}}
      it{expect{subject}.not_to change{translator.user.notifications.count}}
      it{expect{subject}.not_to change{translator_bu.user.notifications.count}}
      it{expect{subject}.not_to change{translator_other.user.notifications.count}}
      it{expect{subject}.not_to change{order.owner.user.notifications.count}}

    end
  end

end