require 'rails_helper'

RSpec.describe Profile::Translator, :type => :model do

  describe '.approving' do

    subject{profile.approving}

    context 'profile has operator' do
      let(:operator) {create :user}
      let(:profile){create :profile_translator, state: :approved, operator: operator}

      it {expect{subject}.to change{profile.reload.operator}.to nil}
    end

    # пока выпилен функционал аппрува раз в сутки
    # context 'more then 1 day' do
    #   let(:profile){create :profile_translator, state: :new, last_sent_to_approvement: DateTime.now - 1.days}
    #
    #   it 'state change' do
    #     subject
    #     expect(profile.reload.state).to eq('approving')
    #   end
    # end
    #
    # context 'last_sent_to_approvement change' do
    #   let(:profile){create :profile_translator, state: :new, last_sent_to_approvement: DateTime.now - 2.days}
    #   it 'last_sent_to_approvement change' do
    #     subject
    #     expect(profile.reload.last_sent_to_approvement).to eq(DateTime.now)
    #   end
    # end
    #
    # context 'less then 1 day' do
    #   let(:profile){create :profile_translator, state: :new, last_sent_to_approvement: DateTime.now - 2.hours}
    #
    #   it 'state not change' do
    #     expect{subject}.not_to change{profile.reload.state}
    #   end
    # end
  end

  describe '#process' do
    let(:operator) {create :user}

    subject{translator.process(operator)}

    context 'profile in ready_for_approvement state' do
      let(:translator) {create :profile_translator, :ready_for_approvement }

      it{expect{subject}.to change{translator.reload.state}.to('approving_in_progress')}
      it{expect{subject}.to change{translator.reload.operator}.to operator}
      it{is_expected.to be_truthy}
    end

    context 'profile in incorrect state' do
      let(:translator) {create :profile_translator, :approved }

      it{expect{subject}.not_to change{translator.reload.state}}
      it{expect{subject}.not_to change{translator.reload.operator}}
      it{is_expected.to be_falsey}
    end
  end

  describe '#busy?' do
    let (:translator) {create :profile_translator}
    subject {translator.busy? argument}

    RSpec.shared_examples 'busy checkers' do
      context 'translators has not busy days on these dates' do
        it {is_expected.to be_falsey}
      end
      context 'translator busy on today' do
        let (:translator) {create :profile_translator, busy_days: [(build :busy_day, date: Date.today)]}
        it {is_expected.to be_truthy}
      end
    end

    context 'pass array of dates' do
      let(:argument) {[Date.today, Date.tomorrow]}
      include_examples 'busy checkers'
    end

    context 'pass a date' do
      let(:argument) {Date.today}
      include_examples 'busy checkers'
    end
  end

  describe '.support_services' do
    let(:city) {create :city}

    let(:step) {build :profile_steps_service, hsk_level: 4, cities: [city]}
    let(:translator_in_scope) {create :profile_translator, profile_steps_service: step, city: city}
    let(:translator_with_other_language) {create :profile_translator,services: [build(:service)] , city: city, profile_steps_service: step}
    let(:translator_with_low_level) {create :profile_translator, services: [build(:service, language: service.language, level: 'guide')], city: city, profile_steps_service: step}
    let(:translator_with_high_level) {create :profile_translator, services: [build(:service, language: service.language, level: 'expert')], city: city, profile_steps_service: step}
    let(:translator_from_other_city) {create :profile_translator, services: [build(:service, language: service.language)]}
    let(:service) {translator_in_scope.services.first}

    before(:each) { translator_with_other_language; translator_with_low_level; translator_with_high_level; translator_from_other_city }
    before(:each) do
      translator_in_scope.city_approves.update_all is_approved: true
      translator_with_low_level.city_approves.update_all is_approved: true
      translator_with_high_level.city_approves.update_all is_approved: true
      service.update level: 2
      service.update! is_approved: true
    end

    subject{Profile::Translator.support_services service.language, city, service.level }

    it{is_expected.to include(translator_in_scope)}
    it{is_expected.to include(translator_with_high_level)}
    it{is_expected.not_to include(translator_with_other_language)}
    it{is_expected.not_to include(translator_with_low_level)}
    it{is_expected.not_to include(translator_from_other_city)}
  end

  describe '#can_process_order?' do
    let(:language){create :language}
    let(:city){create :city}
    let(:translator){create :profile_translator,
                            services: [build(:service, is_approved: true, language: language, level: 'guide')],
                            city_approves: [build(:city_approve, is_approved: true, city: city)]}
    subject{translator.can_process_order? order}

    context 'translator has approved service and city for order' do
      let(:order) {create :wait_offers_order, location: city, language: language, level: 'business'}
      let(:translator){create :profile_translator,
                              services: [build(:service, is_approved: true, language: language, level: level)],
                              city_approves: [build(:city_approve, is_approved: true, city: city)]}


      context "service's lvl is greater than order's lvl" do
        let(:level){'expert'}
        it{is_expected.to be_truthy}
      end

      context "service's lvl is equal order's lvl" do
        let(:level){'business'}
        it{is_expected.to be_truthy}
      end

      context "service's lvl is less than order's lvl" do
        let(:level){'guide'}
        it{is_expected.to be_falsey}
      end
    end

    context 'translator has not approved service' do
      let(:order) {create :wait_offers_order, location: city}

      it{is_expected.to be_falsey}
    end
  end

  context 'build steps' do
    let(:profile){create :profile_translator}

    subject{profile}

    it 'expect service' do
      subject
      expect(profile.profile_steps_service).not_to be_nil
    end

  end

  describe '.support_languages_in_city' do
    let(:target_city) {create :city}
    let(:other_city) {create :city}
    let(:step_service1) {build :profile_steps_service, cities: [target_city]}
    let(:step_service2) {build :profile_steps_service, cities_with_surcharge: [target_city]}
    let(:step_service3) {build :profile_steps_service, cities: [other_city]}

    let(:lang1) {create :language}
    let(:lang2) {create :language}
    let(:lang3) {create :language}
    let(:service1) {create :service, language: lang1}
    let(:service2) {create :service, language: lang2}
    let(:service3) {create :service, language: lang3}

    let(:translator1) {create :profile_translator, profile_steps_service: step_service1,
                              services: [service1, service2]}
    let(:translator2) {create :profile_translator, profile_steps_service: step_service2,
                              services: [service2]}
    let(:translator3) {create :profile_translator, profile_steps_service: step_service3,
                              services: [service3]}

    before(:each){translator1; translator2; translator3}

    subject{Profile::Translator.support_languages_in_city target_city, true}

    it{is_expected.to     include(lang1)}
    it{is_expected.to     include(lang2)}
    it{is_expected.not_to include(lang3)}

    context 'include_closest_cities' do
      subject{Profile::Translator.support_languages_in_city target_city, false}

      it{is_expected.to     include(lang1)}
      it{is_expected.not_to include(lang2)}
      it{is_expected.not_to include(lang3)}
    end
  end

  describe 'changes state' do

    describe '#approving' do
      subject{translator.approving}

      context 'when translator is new' do
        let(:translator) {create :profile_translator}
        it{expect{subject}.to change{translator.state}.from('new').to('ready_for_approvement')}
      end

      context 'when translator is approved' do
        let(:translator) {create :profile_translator, state: :approved}
        it{expect{subject}.to change{translator.state}.from('approved').to('ready_for_approvement')}
      end
    end

    describe '#approve' do
      subject{translator.approve}

      context 'when translator is new' do
        let(:translator) {create :profile_translator, :approving_in_progress}
        it{expect{subject}.to change{translator.state}}
      end

      context 'when translator is approving' do
        let(:translator) {create :profile_translator, :approving_in_progress}
        it{expect{subject}.to change{translator.state}.from('approving_in_progress').to('approved')}
      end
    end

    context 'when services changes' do
      let(:translator) {create :profile_translator, state: :approved}
      let(:service) {translator.services.first}

      context 'when changes writt translation type' do
        subject{service.update_attributes written_translate_type: 'new'}
        it{expect{subject}.to change{translator.state}.from('approved').to('ready_for_approvement')}
      end

      context 'when lvl changes' do
        subject{service.update_attributes level: 'business'}
        it{expect{subject}.to change{translator.state}.from('approved').to('ready_for_approvement')}
      end

      context 'when add new service' do
        subject{create :service, translator: translator}
        it{expect{subject}.to change{translator.state}.from('approved').to('ready_for_approvement')}
      end

      context 'when remove service' do
        subject{translator.services.last.destroy}
        it{expect{subject}.to change{translator.state}.from('approved').to('ready_for_approvement')}
      end
    end


    context 'when cities changes' do
      let(:city) {create :city, name: 'lol?'}
      let(:new_city) {create :city}
      let(:step_service) {build :profile_steps_service, cities: [city]}
      let(:translator) {create :profile_translator, state: :approved,
                               profile_steps_service: step_service}

      context 'when add city' do
        subject{translator.profile_steps_service.update_attributes city_ids: [city.id, new_city.id]}
        it{expect{subject}.to change{translator.state}.from('approved').to('ready_for_approvement')}
      end

      context 'when remove' do
        subject{translator.profile_steps_service.update_attributes city_ids: [new_city.id]}
        it{expect{subject}.to change{translator.state}.from('approved').to('ready_for_approvement')}
      end

    end

    context 'when created level up request' do
      let(:translator) {create :profile_translator, :approved}
      let(:service) {create :service, level: 1, translator: translator}
      let(:lvl_up) {create :level_up_request, from: 1, to: 2}

      subject{service.update_attributes level_up_request: lvl_up}
      it{expect{subject}.to change{translator.reload.state}.from('approved').to('ready_for_approvement')}
    end

  end

  describe '.support_order' do
    let(:city){create :city}
    let(:order){create :order_verbal, reserve_language_criterions: [], reservation_dates: [], location: city}

    before(:each) do
      order.reservation_dates.build(date: '2015-11-11').save!
      1.upto(1000) do
      Profile::Translator.create services: [Profile::Service.create(language: order.main_language_criterion.language,
                                            level: order.main_language_criterion.level, is_approved: true)],
                                            city_approves: [CityApprove.new(city: city, is_approved: true)]
      end

    end
    subject{Profile::Translator.support_order(order)}

    it 'expect time' do
      Benchmark.realtime{subject}.should < 1
    end

  end

  describe '.free_on' do
    let(:busy_day) {build :busy_day}
    let!(:free_translator) {create :profile_translator}
    let!(:busy_translator) {create :profile_translator, busy_days: [busy_day]}

    subject{Profile::Translator.free_on busy_day.date}

    it{is_expected.to include free_translator}
    it{is_expected.not_to include busy_translator}
  end


  describe '.support_written_order' do
    let(:ch_lang) {create :language, is_chinese: true}
    let(:lang) {create :language}
    let(:other_lang) {create :language}

    subject{Profile::Translator.support_written_order order}

    before(:each) {support_order.approve;not_support_order_lang.approve;written_not_approved.approve;not_support_coop.approve}

    let!(:not_approved_translator) {create :profile_translator,
                                          services: [build(:service, written_approves: true, language: lang,
                                                           written_translate_type: 'From-To Chinese')]}
    let!(:not_support_order_lang) {create :profile_translator, :approving_in_progress,
                                     services: [build(:service, written_approves: true, language: other_lang,
                                                      written_translate_type: 'From-To Chinese')]}
    let!(:written_not_approved) {create :profile_translator, :approving_in_progress,
                                          services: [build(:service, written_approves: false, language: lang,
                                                           written_translate_type: 'From-To Chinese')]}
    let!(:not_support_coop) {create :profile_translator, :approving_in_progress,
                                        services: [build(:service, written_approves: true, language: lang,
                                                         written_translate_type: 'From Chinese')]}
    let!(:support_order) {create :profile_translator, :approving_in_progress,
                                    services: [build(:service, written_approves: true, language: lang,
                                                     written_translate_type: 'To Chinese')]}
    #
    # let!(:support_order) {create :profile_translator}

    let(:order) {create :order_written, original_language: lang, translation_language: ch_lang}

    it{is_expected.not_to include not_approved_translator}
    it{is_expected.not_to include not_support_order_lang}
    it{is_expected.not_to include written_not_approved}
    it{is_expected.not_to include not_support_coop}
    it{is_expected.to include support_order}

  end



end