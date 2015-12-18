require 'rails_helper'

RSpec.describe Order::Verbal::EventsService do

  before(:each) do
    Support::Theme.create type: 'no_offers_confirmed', name: 'No translators re-confirmed the order'
    Support::Theme.create type: 'no_translator_found', name: 'No translator found for offer'
  end

  describe '#after_12' do

    let(:translator_1){create :profile_translator}
    let(:translator_2){create :profile_translator}

    subject{Order::Verbal::EventsService.new(order).after_12}

    let(:order){create :order_verbal, state: state}

    context 'state paid' do

      let(:state){'paid'}

      it{expect{subject}.to change{Support::Ticket.count}.by(1)}
      it{expect{subject}.to change{order.state}.to 'confirmation_delay'}
    end

    context 'state confirmed' do

      let(:state){'confirmed'}

      before(:each) do
        order.offers.create! translator: translator_1
        order.offers.create! translator: translator_2
      end

      it{expect{subject}.not_to change{Support::Ticket.count}}
      it{expect{subject}.not_to change{order.state}}

    end
  end

  describe '#after_24' do

    let(:order){create :order_verbal, offers: [], state: state}

    let(:translator){create :profile_translator}

    subject{Order::Verbal::EventsService.new(order).after_24}

    context 'state confirmation_daley' do

      let(:state){'confirmation_delay'}

      it{expect{subject}.to change{order.owner.user.notifications.count}.by(1)}
      it{expect{subject}.to change{order.state}.to 'translator_not_found'}

    end

    context 'state confirmed' do

      let(:state){'confirmed'}

      before(:each){order.offers.create translator: translator }

      it{expect{subject}.not_to change{order.owner.user.notifications.count}}
      it{expect{subject}.not_to change{order.state}}
    end
  end

  describe 'before_60' do

    let(:translator_1){create :profile_translator}
    let(:translator_2){create :profile_translator}

    subject{Order::Verbal::EventsService.new(order).before_60}

    let!(:order){create :order_verbal, offers: [], state: state}

    context 'state confirmed' do

      let(:state){'confirmed'}

      before(:each) do
        order.offers.create! translator: translator_1
        order.offers.create! translator: translator_2
      end

      it{expect{subject}.to change{order.owner.user.notifications.count}.by(1)}
      it{expect{subject}.to change{translator_1.user.reload.notifications.count}.by(1)}
      it{expect{subject}.not_to change{translator_2.user.notifications.count}}
      it{expect{subject}.to change{order.state}.to 'need_reconfirm'}


    end

    context 'state translator not found' do
      let(:state){'translator_not_found'}


      it{expect{subject}.to change{order.owner.user.notifications.count}.by(1)}
      it{expect{subject}.not_to change{order.state}}
    end

  end

  describe 'before_48' do

    let(:order){create :order_verbal, offers: [], state: state}

    context 'state need_reconfirm' do

      let(:state){'need_reconfirm'}

      let(:translator_1){create :profile_translator}
      let(:translator_2){create :profile_translator}

      subject{Order::Verbal::EventsService.new(order).before_48}


      before(:each) do
        order.offers.create! translator: translator_1
        order.offers.create! translator: translator_2
      end

      it{expect{subject}.not_to change{order.owner.user.notifications.count}}
      it{expect{subject}.not_to change{translator_1.user.notifications.count}}
      it{expect{subject}.to change{translator_2.user.reload.notifications.count}.by(1)}
      it{expect{subject}.to change{order.state}.to 'main_reconfirm_delay'}
    end

    context 'state in_progress' do

      let(:state){'in_progress'}

      subject{Order::Verbal::EventsService.new(order).before_48}

      it{expect{subject}.not_to change{order.state}}

    end

  end



  describe '#before_36' do

    subject{Order::Verbal::EventsService.new(order).before_36}

    let(:order){create :order_verbal, state: state}

    context 'translator re-confirmed' do

      let(:state){'in_progress'}

      it{expect{subject}.not_to change{Support::Ticket.count}}
    end

    context 'no translator re-confirmed' do
      let(:state){'main_reconfirm_delay'}
      it{expect{subject}.to change{Support::Ticket.count}.by(1)}
      it{expect{subject}.to change{order.state}.to 'reconfirm_delay'}
    end
  end

  describe '#before_24' do

    subject{Order::Verbal::EventsService.new(order).before_24}

    let(:order){create :order_verbal, state: state}

    context 'translator re-confirmed' do
      let(:state){'in_progress'}

      it{expect{subject}.not_to change{order.owner.user.notifications.count}}
    end

    context 'no translator re-confirmed' do
      let(:state){'reconfirm_delay'}

      it{expect{subject}.to change{order.owner.user.reload.notifications.count}.by(1)}
    end
  end

  describe '#before_4' do

    subject{Order::Verbal::EventsService.new(order).before_4}

    let(:order){create :order_verbal, state: state}

    context 'state reconfirmed_delay' do

      let(:state){'reconfirm_delay'}

      it{expect{subject}.to change{order.state}.to 'canceled_by_yufu'}
      it{expect{subject}.to change{order.owner.user.notifications.count}.by(1)}
    end

    context 'state confirmation_delay' do
      let(:state){'confirmation_delay'}

      it{expect{subject}.to change{order.state}.to 'canceled_by_yufu'}
      it{expect{subject}.to change{order.owner.user.notifications.count}.by(1)}
    end

    context 'state in_progress' do
      let(:state){'in_progress'}

      it{expect{subject}.not_to change{order.state}}
      it{expect{subject}.not_to change{order.owner.user.notifications.count}}
    end

  end

end