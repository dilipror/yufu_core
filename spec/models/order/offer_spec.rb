require 'rails_helper'

RSpec.describe Order::Offer, :type => :model do

  describe '#can_confirm?' do

    let(:translator){create :profile_translator}

    let(:order){create :order_verbal, offers: [], state: state}
    let(:offer){create :order_offer, order: order, translator: translator}
    before(:each){order.stub(:process).and_return(true)}

    subject{offer.confirm}

    context 'can confirm primary' do

      let(:state){'need_reconfirm'}

      it{is_expected.to be_truthy}
      it{ expect{subject}.to change{offer.state}.from('new').to('confirmed')}
    end

    context 'can confirm backup' do

      before(:each) do
        offer.stub(:primary?).and_return(false)
        offer.stub(:back_up?).and_return(true)
      end

      let(:state){'main_reconfirm_delay'}

      it{is_expected.to be_truthy}
      it{expect{subject}.to change{offer.state}.from('new').to('confirmed')}
    end

    context 'can not confirm primary' do

      before(:each) do
        offer.stub(:primary?).and_return(true)
        offer.stub(:back_up?).and_return(false)
        offer.update state: 'new'
      end

      let(:state){'confirmed'}

      it{is_expected.to be_falsey}
      it{ expect{subject}.not_to change{offer.state}.from('new')}
    end

    context 'can not confirm backup' do

      let(:state){'need_reconfirm'}

      before(:each) do
        offer.stub(:primary?).and_return(false)
        offer.stub(:back_up?).and_return(true)
        offer.update state: 'new'
      end

      it{is_expected.to be_falsey}
      it{ expect{subject}.not_to change{offer.state}.from('new')}
    end

    context 'can confirm any' do

      let(:state){'reconfirm_delay'}

      before(:each) do
        offer.stub(:primary?).and_return(false)
        offer.stub(:back_up?).and_return(false)
        offer.update state: 'new'
      end

      it{is_expected.to be_truthy}
      it{ expect{subject}.to change{offer.state}.from('new').to('confirmed')}
    end


  end

  describe 'become main or back_up' do

    let(:translator){create :profile_translator}

    subject{order.offers.create translator: translator}

    context 'main offer' do

      before(:each){Order::Offer.any_instance.stub(:primary?).and_return(true)}

      let(:order){create :order_verbal, offers: []}

      it{expect{subject}.to change{translator.user.reload.notifications.count}.by(1)}
      it{expect{subject}.to change{order.owner.user.notifications.count}.by(1)}

    end

    context 'back_up offer' do
      let(:order){create :order_verbal, offers: []}

      before(:each){create :order_offer, translator: translator, order: order}

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
    let(:order){create :order_verbal, state: 'need_reconfirm'}
    let(:offer){create :order_offer, translator: translator, order: order}
    let(:offer_1){create :order_offer, translator: translator_bu, order: order}
    let(:offer_2){create :order_offer, translator: translator_other, order: order}

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

        let(:offer){create :order_offer, translator: translator, order: order, state: 'rejected'}
        let(:offer_1){create :order_offer, translator: translator_bu, order: order, state: 'rejected'}


        before(:each){
          order.stub(:will_begin_less_than?).with(36.hours).and_return(true)
          order.stub(:process).and_return(true)
          order.stub(:before_60)
          offer
          offer_1
          offer_2
          offer_2.update state: 'new'
        }

        it{expect{subject}.to change{translator_other.user.notifications.count}.by(1)}
        it{expect{subject}.to change{order.owner.user.reload.notifications.count}.by(1)}
        it{expect{subject}.not_to change{translator.user.notifications.count}}
        it{expect{subject}.not_to change{translator_bu.user.notifications.count}}

      end

    end

    context 'can not confirm' do

      before(:each){offer.stub(:can_reconfirm?).and_return(false)}

      it{expect{subject}.not_to change{order.state}}
      it{expect{subject}.not_to change{translator.user.notifications.count}}
      it{expect{subject}.not_to change{translator_bu.user.notifications.count}}
      it{expect{subject}.not_to change{translator_other.user.notifications.count}}
      it{expect{subject}.not_to change{order.owner.user.notifications.count}}

    end

    context '#confirm_after_create' do

      let(:order){create :order_verbal, offers: [], state: state}

      subject{create :order_offer, translator: translator, order: order}

      context 'before 36' do

       let(:state){'reconfirm_delay'}

        it{expect(subject.state).to eq('confirmed')}

      end

      context 'out of time frames' do

        let(:state){'main_reconfirm_delay'}

        it{expect(subject.state).not_to eq('confirmed')}
      end

    end

  end

  describe '#reject' do

    let(:translator){create :profile_translator}
    let(:offer){create :order_offer, translator: translator}

    subject{offer.reject}

    it{expect{subject}.to change{translator.is_banned}.to true}

  end

  describe '#only_one_new_offer' do

    let(:translator){create :profile_translator}

    let(:order){create :order_verbal, offers: []}

    subject do
      offer = (build :order_offer, translator: translator, order: order)
      order.offers << offer
      offer.valid?
    end

    before(:each){order.stub(:will_begin_less_than?).with(36.hours).and_return(false)}

    context 'no offers' do

      it{is_expected.to be_truthy}

    end

    context 'only rejected offer' do
      before(:each){offer = create :order_offer, translator: translator, order: order, state: 'rejected'; order.offers << offer}

      it{is_expected.to be_truthy}

    end

    context 'has offer' do
      before(:each){offer = create :order_offer, translator: translator, order: order; ; order.offers << offer}

      it{is_expected.to be_falsey}
    end

  end

  describe 'mails' do
    before(:each) do
      ActionMailer::Base.delivery_method = :test
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.deliveries = []
    end

    context 'notify_about_order_details_4' do
      subject{create :order_offer}

      it 'mail about_order_details_4 should be sent' do
        subject
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end
    end

  end

end