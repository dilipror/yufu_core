require 'rails_helper'

RSpec.describe Order::Verbal, :type => :model do

  Currency.current_currency = 'USD'


  RSpec.shared_examples 'returns numeric' do
    it 'returns numeric' do
      expect(subject).to be_a(Numeric)
    end
  end

  # RSpec.shared_examples 'returns money' do
  #   it 'returns money' do
  #     expect(subject).to be_a(Money)
  #   end
  # end

  describe '#set_busy_days' do

    before(:each) {order.invoices.create cost: 100.0}

    let(:translator) {create :profile_translator}
    let(:order) {create :order_verbal, state: 'wait_offer'}
    let!(:offer) {Order::Offer.create status: 'primary', translator: translator, order: order}

    subject{order.process}

    it 'assignee should have busy days' do
      subject
      expect(order.assignee.busy_days.map &:date).to eq order.reservation_dates.map &:date
    end
  end

  describe '#skip uncofirmed dates' do

    before(:each)do
      order = create(:order_verbal, state: 'wait_offer')
      order.invoices.create cost: 100.0
      create(:order_offer, status: 'primary', order: order)
      create(:order_offer, status: 'secondary', order: order)
    end

    subject{Order::Verbal.skip_unconfirmed_offers}

    it 'expect only secondary' do
      subject
      expect(Order::Verbal.last.offers.where(status: 'parimary').count).to eq(0)
    end
  end


  describe '#first date' do

    before(:each) {order.invoices.create cost: 100.0}

    let(:order) {create :order_verbal, reservation_dates:[build(:order_reservation_date, date: '2015-10-1'),
                                                          build(:order_reservation_date, date: '2015-10-5')]}
    subject{order.first_date}

    it :expect_date do
      expect(subject).to eq(Date.parse('2015-10-1'))
    end

  end

  describe '#paid' do

    before(:each) {order.invoices.create cost: 100.0}

    let(:order) {create :order_verbal, state: :paying}
    let(:partner) {create :profile_partner, orders: [order]}
    let(:observers_profile) {create :profile_translator, profile_steps_service: {cities: [order.location]},
                                    services: [build(:service,
                                                     language: order.main_language_criterion.language,
                                                     level: order.main_language_criterion.level
                                               )]}
    let(:observer) {observers_profile.user}
    subject{order.paid}

    it{expect{subject}.to change(OrderVerbalQueueFactoryWorker.jobs, :size).by(1)}

    let(:city) {create :city, name: 'NewVasjuki'}
    let(:client) {create :client, email: 'client@example.com'}
    let(:office){create :office, city: city}

    shared_examples 'cash to office' do
      it 'cash to office' do
        expect{subject}.to change{Office.head.balance}.to(order.price)
      end
    end

  end

  # describe '#closed' do
  #   subject{order.close}
  #   let(:client) {create :client, email: 'client@example.com'}
  #   let(:senior_translator){(create :profile_translator).user}
  #   let(:language) {create :language, name: 'NewVasjuki', senior: senior_translator.profile_translator}
  #
  #
  #   let(:lang_criter) {create :order_language_criterion, language: language}
  #
  #   let(:order) {create :order_verbal, owner: client, is_private: false, state: :in_progress, location: city, language: language, level: 'guide',
  #                       assignee: translator.profile_translator, main_language_criterion: lang_criter }
  #
  #   before (:each) do
  #     try(:translator)
  #     try(:senior_translator)
  #     try(:translators_agent)
  #   end
  #
  #   shared_examples 'cash to translator' do
  #     it 'flow' do
  #       expect{subject}.to change{translator.reload.balance.to_f}.to(order.price*0.95*0.7)
  #     end
  #   end
  #
  #   shared_examples 'cash to translators agent' do
  #     it 'flow' do
  #       expect{subject}.to change{translators_agent.reload.balance.to_f}.to(order.price*0.95*0.015)
  #     end
  #   end
  #
  #   shared_examples 'cash to senior translator' do
  #     it 'flow' do
  #       expect{subject}.to change{senior_translator.reload.balance.to_f}.to(order.price*0.95*0.03)
  #     end
  #   end
  #
  #   shared_examples 'cash to translator as executor' do
  #     it 'flow' do
  #       expect{subject}.to change{senior_translator.reload.balance.to_f}.to(order.price*0.95*0.7)
  #     end
  #   end
  #
  #   context 'translator has no agent' do
  #     let(:translator){(create :profile_translator, profile_steps_service: {cities: [city] }).user}
  #
  #     let(:city) {create :city, name: 'NewVasjuki'}
  #     include_examples 'cash to translator'
  #     it 'is closed' do
  #       expect{subject}.to change{order.reload.state}.to('close')
  #     end
  #   end
  #
  #   context 'translator has agent' do
  #     let(:translators_agent){create :user}
  #     let(:translator) do
  #       user = (create :profile_translator, profile_steps_service: {cities: [city] }).user
  #       user.update_attribute :overlord_id, translators_agent.id
  #       user
  #     end
  #     let(:senior_translator){(create :profile_translator).user}
  #     let(:city) {create :city, name: 'NewVasjuki'}
  #     include_examples 'cash to translator'
  #     include_examples 'cash to translators agent'
  #     it 'is closed' do
  #       expect{subject}.to change{order.reload.state}.to('close')
  #     end
  #   end
  #
  #   context 'translator is senior' do
  #     let(:translator){(create :profile_translator, profile_steps_service: { cities: [city]}).user}
  #     let(:senior_translator){(create :profile_translator).user}
  #     let(:city) {create :city, name: 'NewVasjuki'}
  #
  #     let(:language) {create :language, name: 'NewVasjuki', senior: senior_translator.profile_translator}
  #
  #     let(:lang_criter) {create :order_language_criterion, language: language}
  #
  #     let(:order) {create :order_verbal, owner: client, is_private: false, state: :in_progress, location: city,
  #                         assignee: senior_translator.profile_translator, main_language_criterion: lang_criter }
  #     include_examples 'cash to translator as executor'
  #     it 'is closed' do
  #       expect{subject}.to change{order.reload.state}.to('close')
  #     end
  #   end
  #
  #
  # end

  describe '#check_dates' do
    let(:lang) {create :language}
    let(:city) {create :city}
    let(:serv) {create :service, level: 'guide', language: lang}
    let(:translator){(create :profile_translator, profile_steps_service: { cities: [city] }, services: [serv])}

    let(:order) do
      create :order_verbal, step: 1, location: city, main_language_criterion: (build :order_language_criterion, language: lang),
                     reservation_dates: [(build :order_reservation_date, date: '01.02.2014'),
                                         (build :order_reservation_date, date: '02.02.2014')]
    end


    before(:each) {order.invoices.create cost: 100.0}

    before(:each) {translator}

    it 'expect to link criteria an dates' do
      expect(order.reservation_dates.count).to eq(2)
    end

    it 'expect dates without criterion' do
      count = 0
      order.reservation_dates.each do |date|
        unless date.is_confirmed?
          count += 1
        end
      end
      expect(count).to eq(0)
    end

    it '#different' do
      expect(order.different_dates.count).to eq(2)
    end
  end

  describe 'create payment and gateway' do
    let(:order) {create :order_verbal, step: 2}
    let(:bank) {create :payment_bank}

    before(:each) {order.invoices.create cost: 100.0}
    # before(:each) {order.invoices.last.update_attributes wechat: 's', phone: '23'}

    subject{order.update! step: 3, pay_way: bank}

    it 'expect to create payment' do
      expect{subject}.to change{order.payments.last.class}.to eq(Order::Payment)
    end


    it 'expect to create payment' do
      expect{subject}.to change{order.payments.last.try(:gateway_class)}.to eq('Order::Gateway::Bank')
    end

    it 'expect to change state' do
      expect{subject}.to change{order.state}.from('new').to('paying')
    end
  end

  describe 'connect language criterions' do
    let(:order) {create :order_verbal, reserve_language_criterions_count: 10}

    before(:each) {order.invoices.create cost: 100.0}

    it 'creates main criterions' do
      expect(order.main_language_criterion).to be_a(Order::LanguageCriterion)
    end

    it 'creates reserve criterions' do
      expect(order.reserve_language_criterions.count).to eq(10)
      order.reserve_language_criterions.each do |cr|
        expect(cr).to be_a(Order::LanguageCriterion)
      end
    end

  end

  describe '#set_private' do
    let(:order){build :order_verbal, translator_native_language: native_language,
                       main_language_criterion: (build :order_language_criterion, language: main_language)}
    subject{order.save}

    before(:each) {order.invoices.new cost: 100.0}

    context 'office support main language and has local translators' do
      let(:native_language) {create :language, office_has_local_translators: true}
      let(:main_language) {create :language, is_supported_by_office: true}

      it {expect{subject}.to change{order.is_private?}.to(true) }
    end

    context 'office does not support main language' do
      let(:native_language) {create :language, office_has_local_translators: true}
      let(:main_language) {create :language, is_supported_by_office: false}

      it {expect{subject}.not_to change{order.is_private?} }
    end

    context 'office has not local translators' do
      let(:native_language) {create :language, office_has_local_translators: false}
      let(:main_language) {create :language, is_supported_by_office: true}

      it {expect{subject}.not_to change{order.is_private?} }
    end
  end


  describe '#notify about updated' do

    let(:translator){create :profile_translator}
    let(:order) {create :order_verbal, state: 'wait_offer'}
    let(:offer) {create :order_offer, order: order, translator: translator}

    before(:each) {order.invoices.create cost: 100.0}
    # before(:each) {order.invoices.last.update_attributes wechat: 's', phone: '211'}


    subject{order.update airport_pick_up: {departure_city: 'Dushanbe'}}

    before(:each){offer}

    it 'expect notificaions' do
      expect{subject}.to change{translator.user.notifications.count}.by 1
    end

  end

  describe '#set_langvel' do

    subject{order.update include_near_city: true}

    context 'langvel nil' do

      before(:each) {order.invoices.create! cost: 100.0}

      let(:order){create :order_verbal, language_id: nil, level: nil}


      it do
        subject
        expect(order.reload.language).to eq(order.main_language_criterion.language)
      end

      it do
        subject
        expect(order.level).to eq(order.main_language_criterion.level)
      end

    end

  end

  describe '#original_price' do

    before(:each) {order.invoices.create cost: 100.0}

    let(:order) {create :order_verbal, include_near_city: false}
    subject{order.original_price}
    it 'returns cost only for reserved dates, without additions' do
      order.reservation_dates.first.update is_confirmed: true
      expect(subject).to eq(order.reservation_dates.first.original_price)
    end
    # include_examples 'returns numeric'
    it{is_expected.to be_a BigDecimal}
  end

  describe 'office' do
    subject{order.office}
    context 'order has not location' do
      let(:order) {create :order_verbal, location: nil}

      it{is_expected.to eq Office.head}
    end

    context 'order has location' do
      let(:order) {create :order_verbal, location: location}
      context 'location has office' do
        let(:office){create :office}
        let(:location){create :city, office: office}

        it{is_expected.to eq office}
      end

      context 'location has not office' do
        let(:location){create :city}
        it{is_expected.to eq Office.head}
      end
    end
  end

  describe '#there_are_translator_with_surcharge?' do
    let(:translator){create :full_approved_profile_translator}
    let!(:city_approve) {create :city_approve, with_surcharge: true, translator: translator}

    subject{order.there_are_translator_with_surcharge?}

    before(:each) {order.invoices.create cost: 100.0}

    context 'when no translator with surcharge with language' do
      let(:order) {create :order_verbal,
                          location: translator.city_approves.first.city,
                          level: translator.services.first.level}
      it{is_expected.to eq false}
    end

    context 'when no translator with surcharge in city' do
      let(:order) {create :order_verbal, language: translator.services.first.language,
                          level: translator.services.first.level}
      it{is_expected.to eq false}
    end

    context 'when there are translator with surcharge' do
      let(:order) {create :order_verbal, language: translator.services.first.language,
                          location: translator.city_approves.last.city,
                          level: translator.services.first.level}
      it{is_expected.to eq true}
    end
  end

  describe '#paying_items' do

    subject{order.paying_items}

    before(:each) {order.invoices.create cost: 100.0}

    let(:order){create :order_verbal, reservation_dates: reservation_dates}

    before(:each) do
      Language.any_instance.stub(:verbal_price).and_return(10)
    end

    RSpec.shared_examples 'control sum' do
      it 'expect that total sum is eq sum of dates original prices' do
        check_sum = order.reservation_dates.offset(1).inject(0) {|sum, date| sum + date.original_price}
        check_sum += order.reservation_dates.first.original_price_without_overtime
        check_sum += order.reservation_dates.first.overtime_price is_first_date: true,
                                                                  work_start_at: order.greeted_at_hour
        expect(
            subject.inject(0){|sum, item| sum + item[:cost]}
        ).to eq(check_sum)
      end
    end

    context 'has over time' do
      let(:order){create :order_verbal, greeted_at_hour: 3,
                         reservation_dates: [(build :order_reservation_date, hours: 10, date: '2015-10-01'),
                                             (build :order_reservation_date, hours: 8, date: '2015-10-02'),
                                             (build :order_reservation_date, hours: 12, date: '2015-10-03'),
                                             (build :order_reservation_date, hours: 4, date: '2015-10-04')]}
      it {expect(subject.count).to eq(order.reservation_dates.count + 1)}
      include_examples 'control sum'
    end

    context 'has not overtime' do
      let(:order){create :order_verbal, greeted_at_hour: 7,
                         reservation_dates: [(build :order_reservation_date, hours: 8, date: '2015-10-01')]}

      it {expect(subject.count).to eq order.reservation_dates.count}

      include_examples 'control sum'
    end

  end

  describe '#first_date_time' do

    let(:order){create :order_verbal, greeted_at_hour: 12, greeted_at_minute: 37}

    before(:each){order.reservation_dates.first.stub(:date).and_return(Time.parse('03.11.2015'))}

    subject{order.first_date_time}

    it{is_expected.to eq(Time.parse('12:37 03.11.2015'))}

  end

  describe 'timestamps' do

    describe '#paid_ago?' do
      subject{order.paid_ago?(12.hours)}
      let(:order){create :order_verbal}

      context 'before time' do


        before(:each)do
          order.stub(:paid_time).and_return(Time.parse('11:33 03.11.2015') - 14.hours)
          Time.stub(:now).and_return(Time.parse('11:33 03.11.2015'))
        end

        it{is_expected.to be_truthy}

      end

      context 'just in time' do
        before(:each)do
          order.stub(:paid_time).and_return(Time.parse('11:33 03.11.2015') - 12.hours)
          Time.stub(:now).and_return(Time.parse('11:33 03.11.2015'))
        end

        it{is_expected.to be_truthy}
      end

      context 'after time'do

        before(:each)do
          order.stub(:paid_time).and_return(Time.parse('11:33 03.11.2015') - 10.hours)
          Time.stub(:now).and_return(Time.parse('11:33 03.11.2015'))
        end

        it{is_expected.to be_falsey}
      end
    end

    describe 'will_begin_less_than?' do

      subject{order.will_begin_less_than?(60.hours)}

      context 'before time' do
        let(:order){create :order_verbal}


        before(:each)do
          Time.stub(:now).and_return(Time.parse('11:33 03.11.2015') - 61.hours)
          order.stub(:first_date_time).and_return(Time.parse('11:33 03.11.2015'))
        end

        it{is_expected.to be_falsey}

      end

      context 'just in time' do
        let(:order){create :order_verbal}


        before(:each)do
          Time.stub(:now).and_return(Time.parse('11:33 03.11.2015') - 60.hours)
          order.stub(:first_date_time).and_return(Time.parse('11:33 03.11.2015'))
        end

        it{is_expected.to be_truthy}

      end

      context 'after time' do
        let(:order){create :order_verbal}



        before(:each)do
          Time.stub(:now).and_return(Time.parse('11:33 03.11.2015') - 59.hours)
          order.stub(:first_date_time).and_return(Time.parse('11:33 03.11.2015'))
        end

        it{is_expected.to be_truthy}

      end

    end
  end

  describe 'events' do

    before(:each) do
      Support::Theme.create type: 'no_offers_confirmed', name: 'No translators re-confirmed the order'
      Support::Theme.create type: 'no_translator_found', name: 'No translator found for offer'
    end

    describe '#after_12' do

      let(:translator_1){create :profile_translator}
      let(:translator_2){create :profile_translator}

      subject{order.after_12}

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

      subject{order.after_24}

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

      let(:translator_1){create :profile_translator}
      let(:translator_2){create :profile_translator}

      subject{order.before_60}

      let(:order){create :order_verbal, offers: []}

      before(:each) do
        order.offers.create! translator: translator_1
        order.offers.create! translator: translator_2
      end

      it{expect{subject}.to change{order.owner.user.notifications.count}.by(1)}
      it{expect{subject}.to change{translator_1.user.reload.notifications.count}.by(1)}
      it{expect{subject}.not_to change{translator_2.user.notifications.count}}

    end

    describe 'before_48' do

      let(:translator_1){create :profile_translator}
      let(:translator_2){create :profile_translator}

      subject{order.before_48}

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

      subject{order.before_36}

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

      subject{order.before_24}


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

      subject{order.before_4}

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

        it{expect{subject}.to change{order.owner.user.notifications.count}.by(1)}
        it{expect{subject}.to change{order.state}.to('rejected')}
        it{expect{subject}.to change{order.owner.user.balance}}
      end

    end
  end

end