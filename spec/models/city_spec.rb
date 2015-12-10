require 'rails_helper'
require 'mongoid/criteria'

RSpec.describe City, type: :model do
  describe '.available_for' do
    let(:not_approved_city ) {create :city}
    let(:approved_city)      {create :city}
    let(:other_city)         {create :city}
    let(:translator) {create :profile_translator,
                             state: :approved,
                             profile_steps_service: create(:profile_steps_service,
                                                           cities: [approved_city, not_approved_city])}
    before(:each) do
      not_approved_city
      other_city
      CityApprove.where(city_id: approved_city.id,
                        translator_id: translator.id).update_all(is_approved: true)
    end

    subject{City.available_for translator}

    it{is_expected.to include(approved_city)}
    it{is_expected.not_to include(not_approved_city)}
    it{is_expected.not_to include(other_city)}
  end

  describe '.with_approved_translators' do
    let(:not_approved_city ) {create :city}
    let(:approved_city) {create :city}

    before(:each) do
      CityApprove.where(city_id: approved_city.id,
                        translator_id: translator.id).update_all(is_approved: true)
    end

    subject {City.with_approved_translators}

    context 'translator is approved' do
      let(:translator) {create :profile_translator,
                               state: :approved,
                               profile_steps_service: create(:profile_steps_service,
                                                             cities: [approved_city, not_approved_city])}
      it { is_expected.to     include(approved_city) }
      it { is_expected.not_to include(not_approved_city) }
    end

    context 'translator is not approved' do
      let(:translator) {create :profile_translator,
                               state: :new,
                               profile_steps_service: create(:profile_steps_service,
                                                             cities: [approved_city, not_approved_city])}
      it { is_expected.not_to include(approved_city) }
      it { is_expected.not_to include(not_approved_city) }
    end
  end

  describe '.available_for_order' do
    let(:city_1){create :city}
    let(:city_2){create :city}
    let(:city_3){create :city}
    let(:city_4){create :city}
    let(:city_5){create :city}

    let!(:translator_1){create :profile_translator, city_approves: [(create :city_approve, city: city_1)]}
    let!(:translator_2){create :profile_translator, city_approves: [(create :city_approve, city: city_2)]}
    let!(:translator_3){create :profile_translator, city_approves: [(create :city_approve, city: city_2)],
                               services: [(create :service, is_approved: false)]}
    let!(:translator_4){create :profile_translator, city_approves: [(create :city_approve, city: city_2)], services:[]}

    subject{City.available_for_order}
    it{expect(subject.count).to eq(2)}
    it{is_expected.to include(city_1)}
    it{is_expected.to include(city_2)}

  end

  describe '.supported' do
    let(:approved_approve) {create :city_approve}
    let(:approved_with_surcharge) {create :city_approve, with_surcharge: true}
    let(:not_approved_approve) {create :city_approve, is_approved: false}

    let(:approved_city) {approved_approve.city}
    let(:approved_city_with_surcharge) {approved_with_surcharge.city}
    let(:not_approved_city) {not_approved_approve.city}

    before(:each) {approved_city; approved_city_with_surcharge; not_approved_city}

    subject{City.supported}

    it{is_expected.to include(approved_city)}
    it{is_expected.to include(approved_city_with_surcharge)}
    it{is_expected.not_to include(not_approved_city)}
  end

  describe '#languages_ids' do

    # let(:city_approve){(create :city_approve, is_approved: true)}

    let(:city){create :city}


    let(:translator){create :profile_translator, city: city, services: []}

    let(:language_1){create :language}
    let(:language_2){create :language}

    let(:service_1){create :service, only_written: true, translator: translator, is_approved: true}
    let(:service_2){create :service, only_written: false, translator: translator, is_approved: true}

    subject{city.language_ids false}

    before(:each) do
      service_1
      service_2
      CityApprove.create city: city, is_approved: true, translator: translator
    end

    it{ is_expected.to include(service_2.language_id) }
    it{ expect(subject.length).to eq(1) }
  end
end