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

  describe 'change order state' do
    let(:bank) {create :payment_bank}
    describe 'to paid' do

      before(:each) {order.invoices.create cost: 100.0}

      let(:order) {create :order_verbal, step: 3, pay_way: bank}

      subject{order.payments.first.update_attribute :state, 'paid'}

      it 'expect order to be paid' do
        expect{subject}.to change{order.state}.to('wait_offer')
      end
    end

    describe 'to unpaid' do

      before(:each) {order.invoices.create cost: 100.0}

      let(:order) {create :order_verbal, step: 3, pay_way: bank}

      subject{order.payments.first.update_attribute :state, 'paying'}

      before(:each) do
        order.payments.first.update_attribute :state, 'paid'
      end

      it 'expect order to be paid' do
        order.paid
        expect{subject}.to change{order.state}.to('paying')
      end

      it 'can not change from closed' do
        order.update_attribute :state, 'close'
        subject
        expect(order.state).to eq('close')
      end

      it 'can not change from rated' do
        order.update_attribute :state, 'rated'
        expect(order.state).to eq('rated')
      end

      it 'can not change from in_progress' do
        order.update_attribute :state, 'in_progress'
        expect(order.state).to eq('in_progress')
      end
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

  describe '.default_scope_for' do
    context 'profile is a translator' do

      let(:city) {create :city}
      let(:profile) do
        create :profile_translator
               # city_approves: [CityApprove.create(city: city, with_surcharge: false)]
      end
      let(:city_approve) {create :city_approve, city: city, with_surcharge: false, translator: profile}
      let(:service) {profile.services.first}

      before(:each) {order_supported_by_profile.invoices.create cost: 100.0}

      let(:order_supported_by_profile) do
        create :order_verbal,
               # main_language_criterion: (build :order_language_criterion,
               #                                 language: service.language,
               #                                 level: service.level),
               location: city,
               include_near_city: false,
               created_at: DateTime.now.utc - 1.day,
               language: service.language,
               level: service.level
      end
      let(:other_order) {create :order_verbal}
      before(:each) {order_supported_by_profile; other_order; city_approve}
      subject{Order::Verbal.default_scope_for profile}

      it {is_expected.to include(order_supported_by_profile)}
      it {is_expected.not_to include(other_order)}
    end
  end

  describe '.available_for' do
    context 'profile is a translator' do
      let(:city) {create :city}
      let(:city1) {create :city}

      let(:senior) {create :profile_translator}

      let(:profile) {create :profile_translator}

      let(:service) {profile.services.first}

      before(:each) {order_supported_by_profile.invoices.create cost: 100.0}

      let(:order_supported_by_profile) do
        create :order_verbal,
               # main_language_criterion: (build :order_language_criterion,
               #                                 language: service.language,
               #                                 level: service.level),
               location: city,
               include_near_city: false,
               created_at: DateTime.now.utc - 1.day,
               language: service.language,
               level: service.level
      end

      let(:order_created_at_less_30_min) do
        create :order_verbal,
               # main_language_criterion: (create :order_language_criterion,
               #                                 language: service.language,
               #                                 level: service.level),
               location: city,
               include_near_city: false,
               language: service.language,
               level: service.level
      end

      let(:other_order) {create :order_verbal}

      before(:each) do
        order_supported_by_profile; other_order; order_created_at_less_30_min
        create :city_approve, city: city, with_surcharge: false, translator: profile
        create :city_approve, city: city, with_surcharge: false, translator: senior

        create :city_approve, city: city1, with_surcharge: false, translator: profile
        create :city_approve, city: city1, with_surcharge: false, translator: senior
      end
      subject{Order::Verbal.available_for profile}

      it{is_expected.to be_a Mongoid::Criteria}

      context 'translator is not senior' do
        before(:each) {service.language.update! senior: senior}

        it {is_expected.to include(order_supported_by_profile)}
        it {is_expected.not_to include(other_order)}
        it {is_expected.not_to include(order_created_at_less_30_min)}
      end

      context 'translator is senior' do
        before(:each) {service.language.update! senior: profile}

        it {is_expected.to include(order_supported_by_profile)}
        it {is_expected.to include(order_created_at_less_30_min)}
        it {is_expected.not_to include(other_order)}
      end

      context 'no senior' do
        it {is_expected.to include(order_supported_by_profile)}
        it {is_expected.to include(order_created_at_less_30_min)}
        it {is_expected.not_to include(other_order)}
      end

    end

    context 'perfomance tests' do

      subject{Order::Verbal.available_for profile}

      let(:city) {create :city}

      let(:senior) {create :profile_translator}

      let(:profile) {create :profile_translator}

      let(:service) {profile.services.first}

      let(:order_supported_by_profile) do
        create :order_verbal,
               main_language_criterion: (build :order_language_criterion,
                                               language: service.language,
                                               level: service.level),
               location: city,
               include_near_city: false,
               created_at: DateTime.now.utc - 1.day
      end

      before(:each) {order_created_at_less_30_min.invoices.create! cost: 100.0}

      let(:order_created_at_less_30_min) do
        create :order_verbal,
               main_language_criterion: (create :order_language_criterion,
                                                language: service.language,
                                                level: service.level),
               location: city,
               include_near_city: false
      end

      let(:other_order) {create :order_verbal}

      before(:each) do
        1.upto(1000) do
          Order::Verbal.create main_language_criterion: Order::LanguageCriterion.create(language: service.language,
              level: service.level),    location: city,
                               include_near_city: false
        end
        # create_list :translator, 100
        #
        # create_list :order_verbal, 100
        order_supported_by_profile; other_order; order_created_at_less_30_min
        create :city_approve, city: city, with_surcharge: false, translator: profile
        create :city_approve, city: city, with_surcharge: false, translator: senior
      end

      it 'expect time' do
        Benchmark.realtime{subject}.should < 25
      end

    end
  end


  describe '#notify about updated' do

    let(:translator){create :profile_translator}
    let(:order) {create :order_verbal, state: 'wait_offer'}
    let(:offer) {create :order_offer, order: order, translator: translator}

    before(:each) {order.invoices.create cost: 100.0}

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

    let(:order){create :order_verbal, reservation_dates: [(build :order_reservation_date, hours: 8, date: '2015-10-01'),
                                                          (build :order_reservation_date, hours: 10, date: '2015-10-02'),
                                                          (build :order_reservation_date, hours: 12, date: '2015-10-03')]}

    before(:each) do
      Language.any_instance.stub(:verbal_price).and_return(10)
    end

    context 'first day with greeted_at' do

      let(:order){create :order_verbal, greeted_at_hour: greeted_at_hour, greeted_at_minute: greeted_at_minute, reservation_dates: [(build :order_reservation_date, hours: hours, date: '2015-10-01')]}

      context 'in time' do
        let(:greeted_at_hour){8}
        let(:greeted_at_minute){16}
        let(:hours){8}

        it {expect(subject[0][:cost]).to eq(80)}
        it {expect(subject[1]).to be_nil}
      end


      context 'in time x 2' do
        let(:greeted_at_hour){8}
        let(:greeted_at_minute){16}
        let(:hours){4}

        it {expect(subject[0][:cost]).to eq(60)}
        it {expect(subject[1]).to be_nil}
      end

      context 'in time with overtime' do
        let(:greeted_at_hour){8}
        let(:greeted_at_minute){16}
        let(:hours){10}

        it {expect(subject[0][:cost]).to eq(80)}
        it {expect(subject[1][:cost]).to eq(30)}
      end

      context 'all before' do
        let(:greeted_at_hour){0}
        let(:greeted_at_minute){16}
        let(:hours){4}

        it {expect(subject[0][:cost]).to eq(90)}
        it {expect(subject[1]).to be_nil}
      end

      context 'all after' do
        let(:greeted_at_hour){22}
        let(:greeted_at_minute){16}
        let(:hours){8}

        it {expect(subject[0][:cost]).to eq(120)}
        it {expect(subject[1]).to be_nil}
      end

      context 'partially before' do
        let(:greeted_at_hour){6}
        let(:greeted_at_minute){15}
        let(:hours){8}

        it {expect(subject[0][:cost]).to eq(70)}
        it {expect(subject[1][:cost]).to eq(15)}
      end

      context 'partially after' do
        let(:greeted_at_hour){14}
        let(:greeted_at_minute){15}
        let(:hours){10}

        it {expect(subject[0][:cost]).to eq(70)}
        it {expect(subject[1][:cost]).to eq(45)}
      end

      context 'partially before and after' do
        context 'partially before' do
          let(:greeted_at_hour){6}
          let(:greeted_at_minute){15}
          let(:hours){16}

          it {expect(subject[0][:cost]).to eq(80)}
          it {expect(subject[1][:cost]).to eq(120)}
        end
      end

    end

    it 'first item' do
      expect(subject[0][:cost]).to eq(80)
      expect(subject[0][:description]).to eq('For date 2015-10-01 8 hours')
    end

    it 'second item' do
      expect(subject[1][:cost]).to eq(80)
      expect(subject[1][:description]).to eq('For date 2015-10-02 8 hours')
    end

    it 'third item' do
      expect(subject[2][:cost]).to eq(80)
      expect(subject[2][:description]).to eq('For date 2015-10-03 8 hours')
    end

  end

end