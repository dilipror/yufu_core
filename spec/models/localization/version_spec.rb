require 'rails_helper'

RSpec.describe Localization::Version, type: :model do
  describe '.approve' do
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
      it 'creates version for chinese' do
        expect{subject}.to change{Localization::Version.count}.by(1)
      end
    end

    context 'approve chinese' do
      let(:localization) {create :localization, language: create(:language, is_chinese: true), name: 'cn-pseudo'}
      let(:other_locale) { create :localization, name: 'ru'}

      it 'creates version for all other locales' do
        expect{subject}.to change{Localization::Version.count}.by(1)
      end
    end

    context 'approve other language' do
      let(:localization) { create :localization, name: 'fr'}
      it { expect{subject}.not_to change{Localization::Version.count}}
    end

  end
end