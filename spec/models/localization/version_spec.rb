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
end