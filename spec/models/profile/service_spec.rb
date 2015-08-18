require 'rails_helper'

RSpec.describe Profile::Service, type: 'model' do

  describe '.only_written' do
    let(:written_service) {create :service, only_written: true}
    let(:service) {create :service, only_written: false}
    let(:translator) {create :profile_translator, services: [written_service, service]}

    subject{translator.services.only_written}

    it{is_expected.to include written_service}
    it{is_expected.not_to include service}
  end

  describe '.not_only_written' do
    let(:written_service) {create :service, only_written: true}
    let(:service) {create :service, only_written: false}
    let(:translator) {create :profile_translator, services: [written_service, service]}

    subject{translator.services.not_only_written}

    it{is_expected.not_to include written_service}
    it{is_expected.to include service}
  end

  describe '#can_make_senior?' do
    subject{service.can_make_senior?}

    context 'service without claim' do
      let(:service){create :service, claim_senior: false}
      it{is_expected.to be_falsey}
    end

    context 'service with claim' do
      let(:service){create :service, claim_senior: true, language: language}

      context 'language has senior' do
        let(:language) {create :language, senior: create(:profile_translator)}
        it{is_expected.to be_falsey}
      end

      context 'language has not senior' do
        let(:language) {create :language}
        it{is_expected.to be_truthy}
      end
    end
  end

  describe '#make_senior' do
    let(:translator) {create :profile_translator}
    let(:service){create :service, claim_senior: true, language: language, translator: translator}

    subject{service.make_senior}

    before(:each){service.translator.user.password = nil}

    context 'can make senior' do
      let(:language) {create :language, name: 'French'}
      let(:profile){create :profile_translator}
      let(:service){create :service, claim_senior: true, language: language, translator: profile}


      it {expect{subject}.to change{service.reload.language.senior}.to(service.translator)}
      it{is_expected.to be_truthy}

      context 'there is localization' do
        let(:localization) {create :localization, name: 'es', language: service.language}

        it 'adds user to localization' do
          expect{subject}.to change{localization.users.count}.by(1)
        end
      end
      context 'there is not localization' do
        it{expect{subject}.to change{Localization.count}.by(1)}

        it 'creates a new localization specific language' do
          subject
          expect(Localization.where(language_id: service.language_id).first.present?).to be_truthy
        end

        it 'adds user to a new localization' do
          subject
          expect(Localization.where(language_id: service.language_id).first.users).to include(service.translator.user)
        end
      end
    end

    context 'cannot make senior' do
      subject{service.make_senior}
      let(:profile_translator){create :profile_translator}
      let(:language) {create :language, senior: profile_translator}
      let(:service){create :service, claim_senior: true, language: language, translator: profile_translator}

      it{expect{subject}.not_to change{Localization.count}}
      it{is_expected.to be_falsey}
    end
  end
end