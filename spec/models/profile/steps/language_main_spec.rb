require 'rails_helper'

RSpec.describe Profile::Steps::LanguageMain do
  describe '#build_default_service' do
    let(:translator) {create :profile_translator}
    let(:step_language) {translator.profile_steps_language}
    let(:country) {create :country}

    subject{step_language.update native_language_id: language.id, citizenship: country}


    context 'native language is chinese' do
      let(:language){create :language, is_chinese: true}

      it 'does not create new service' do
        expect{subject}.not_to change{translator.services.count}
      end
    end

    context 'native language is not chinese' do

      let(:language){create :language, is_chinese: false, name: 'lol'}
      let(:translator) {create :profile_translator, profile_steps_language: {native_language: language}, services: []}
      let(:step_language) {translator.profile_steps_language}
      # before(:each) {translator.services.delete_all}

      subject{translator}
      context 'translator has not a service' do
        it 'creates new service' do
          subject
          expect(translator.services.count).to eq(1)
        end

        it 'creates new service with lang eq native' do
          subject
          expect(translator.services.first.language).to eq(language)
        end
      end

      context 'translator has a service' do
        let(:translator) {create :profile_translator, services: [build(:service)]}
        it {expect{subject}.not_to change{translator.services.count}}
      end
    end
  end
end