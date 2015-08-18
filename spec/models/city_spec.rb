require 'rails_helper'

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
end