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

    let(:order){create :order_verbal, offers: []}

    context 'no offers' do

      it{expect{subject}.to change{Support::Ticket.count}.by(1)}
    end

    context 'has offer' do

      before(:each) do
        order.offers.create! translator: translator_1
        order.offers.create! translator: translator_2
      end

      it{expect{subject}.not_to change{Support::Ticket.count}}

    end
  end

  describe '#after_24' do

    let(:translator){create :profile_translator}

    subject{Order::Verbal::EventsService.new(order).after_24}

    context 'no offer' do
      let(:order){create :order_verbal, offers: []}

      it{expect{subject}.to change{order.owner.user.notifications.count}.by(1)}

    end

    context 'offers exist' do
      let(:order){create :order_verbal, offers: []}

      before(:each){order.offers.create translator: translator }

      it{expect{subject}.not_to change{order.owner.user.notifications.count}}
    end
  end
  describe 'before_60' do

    context 'has main_offer' do

      let(:translator_1){create :profile_translator}
      let(:translator_2){create :profile_translator}

      subject{Order::Verbal::EventsService.new(order).before_60}

      let(:order){create :order_verbal, offers: []}

      before(:each) do
        order.offers.create! translator: translator_1
        order.offers.create! translator: translator_2
      end

      it{expect{subject}.to change{order.owner.user.notifications.count}.by(1)}
      it{expect{subject}.to change{translator_1.user.reload.notifications.count}.by(1)}
      it{expect{subject}.not_to change{translator_2.user.notifications.count}}

    end

    context 'no main_offer' do

      let(:translator_1){create :profile_translator}
      let(:translator_2){create :profile_translator}

      subject{Order::Verbal::EventsService.new(order).before_60}

      let(:order){create :order_verbal, offers: []}


      it{expect{subject}.not_to change{order.owner.user.notifications.count}}
      it{expect{subject}.not_to change{translator_1.user.reload.notifications.count}}
      it{expect{subject}.not_to change{translator_2.user.notifications.count}}

    end



  end

  describe 'before_48' do

    let(:translator_1){create :profile_translator}
    let(:translator_2){create :profile_translator}

    subject{Order::Verbal::EventsService.new(order).before_48}

    let(:order){create :order_verbal, offers: []}

    before(:each) do
      order.offers.create! translator: translator_1
      order.offers.create! translator: translator_2
    end

    it{expect{subject}.not_to change{order.owner.user.notifications.count}}
    it{expect{subject}.not_to change{translator_1.user.notifications.count}}
    it{expect{subject}.to change{translator_2.user.reload.notifications.count}.by(1)}

  end



  describe '#before_36' do

    subject{Order::Verbal::EventsService.new(order).before_36}

    context 'translator re-confirmed' do
      let(:order){create :order_verbal, state: 'in_progress'}

      it{expect{subject}.not_to change{Support::Ticket.count}}
    end

    context 'no translator re-confirmed' do
      let(:order){create :order_verbal, state: 'wait_offer'}
      it{expect{subject}.to change{Support::Ticket.count}.by(1)}
    end
  end

  describe '#before_24' do

    subject{Order::Verbal::EventsService.new(order).before_24}


    context 'translator re-confirmed' do
      let(:order){create :order_verbal, state: 'in_progress'}

      it{expect{subject}.not_to change{order.owner.user.notifications.count}}
    end

    context 'no translator re-confirmed' do
      let(:order){create :order_verbal, state: 'wait_offer'}

      it{expect{subject}.to change{order.owner.user.reload.notifications.count}.by(1)}
    end
  end

  describe '#before_4' do

    subject{Order::Verbal::EventsService.new(order).before_4}

    let(:invoice){create :invoice}
    before(:each) do
      # invoice.client_info.stub(:invoice).and_return(invoice)
      allow(order).to receive(:will_begin_less_than?).with(4.hours).and_return true
      allow(order).to receive(:will_begin_less_than?).with(36.hours).and_return true
      order.invoices.first.transactions.create sum: 100, state: 'executed', debit: order.owner.user, credit: Office.head
    end

    context 'translator re-confirmed' do
      let(:order){create :order_verbal, state: 'in_progress', invoices: [invoice]}

      it{expect{subject}.not_to change{order.owner.user.notifications.count}}
      it{expect{subject}.not_to change{order.owner.user.balance}}
    end

    context 'no translator re-confirmed' do
      let(:order){create :order_verbal, state: 'wait_offer', invoices: [invoice]}

      it{expect{subject}.to change{order.owner.user.notifications.count}.by(2)}
      it{expect{subject}.to change{order.state}.to('rejected')}
      it{expect{subject}.to change{order.owner.user.balance}}
    end

  end

end