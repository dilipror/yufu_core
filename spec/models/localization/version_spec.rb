require 'rails_helper'

RSpec.describe Localization::Version, type: :model do
  describe '#approve' do
    let(:version){create :localization_version, localization: localization, state: 'commited'}
    subject{version.approve}

    before(:each){version}

    context 'approve english' do
      let(:localization){Localization.default}
      before(:each) do
        chinese = create :language, is_chinese: true
        create :localization, language: chinese, name: 'cn-pseudo'
        version
      end
      it 'creates version for pseudo chinese' do
        expect{subject}.to change{Localization::Version.count}.by(1)
      end

      describe 'created version after approve' do
        before(:each){version.approve}
        subject{Localization::Version.last}

        it {expect(subject.parent_version).to eq version}
        it {expect(subject.name).to eq version.name}
      end
    end

    context 'approve chinese' do
      let(:localization) {create :localization, language: create(:language, is_chinese: true), name: 'cn-pseudo'}
      let(:english_version){create :localization_version, localization: Localization.default}
      let(:other_locale) { create :localization, name: 'ru'}
      let(:version){create :localization_version, localization: localization, state: 'commited', parent_version: english_version}

      it 'creates version for all other locales' do
        expect{subject}.to change{Localization::Version.count}.by(1)
      end

      describe 'created version after approve' do
        before(:each){version.approve}
        subject{Localization::Version.last}

        it {expect(subject.parent_version).to eq english_version}
        it {expect(subject.name).to eq version.name}
      end
    end

    context 'approve other language' do
      let(:localization) { create :localization, name: 'fr'}
      it { expect{subject}.not_to change{Localization::Version.count}}
    end

  end

  describe '#delete_version' do
    let(:version){create :localization_version, localization: localization, state: 'approved',
                         translations: [translation]}
    let(:localization){Localization.default}
    let(:translation){create :translation}

    subject{version.delete_version}

    it 'version should be deleted' do
      subject
      expect(version.deleted?).to eq true
      expect(version.translations.first.deleted?).to eq true
      expect(version.state_before_delete).to eq 'approved'
    end
  end

  describe '#restore_version' do
    let(:version){create :localization_version, localization: localization, state: 'removed',
                         translations: [translation], deleted_at: Time.now, state_before_remove: 'commited'}
    let(:localization){Localization.default}
    let(:translation){create :translation, deleted_at: Time.now}

    subject{version.restore_version}

    it 'version should be restored' do
      subject
      expect(version.deleted?).to eq false
      expect(version.translations.first.deleted?).to eq false
      expect(version.state).to eq 'commited'
      expect(version.state_before_remove).to eq nil
    end
  end
end