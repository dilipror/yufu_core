require 'rails_helper'

RSpec.describe Yufu::TranslationProxy do
  describe '.update' do
    let(:version){create :localization_version}

    subject{Yufu::TranslationProxy.update 'key', 'new value', version}

    context 'translation is presented' do
      let(:translation){create :translation, version: version}
      before(:each){translation}

      it{expect{subject}.not_to change{Translation.count}}
      it{expect{subject}.to change{translation.reload.value}.to 'new value'}
    end

    context 'translation is not presented' do
      it{expect{subject}.to change{Translation.count}.by(1)}
    end
  end


  describe '.only_updated' do
    subject{Yufu::TranslationProxy.only_updated(version).map(&:key)}
    context 'english version' do
      let(:version){create :localization_version, localization: Localization.default}
      let(:new_translations){create :translation, version: version}

      before(:each){new_translations}

      it{is_expected.to include new_translations.key}
    end

    context 'not english version' do
      let(:first){create :localization_version_number}
      let(:second){create :localization_version_number}
      let(:third){create :localization_version_number}

      let(:first_version){create :localization_version, :approved, version_number: first, localization: Localization.default}
      let(:second_second){create :localization_version, :approved, version_number: second, localization: Localization.default}
      let(:third_second){create :localization_version, :approved, version_number: third, localization: Localization.default}
      let(:translation_from_first){create :translation, version: first_version}
      let(:translation_from_second){create :translation, version: second_second}
      let(:translation_from_third){create :translation, version: third_second}

      let(:version){create :localization_version, version_number: second}

      before(:each){translation_from_first; translation_from_second; translation_from_third}

      it{is_expected.to include translation_from_first.key}
      it{is_expected.to include translation_from_second.key}
      it{is_expected.not_to include translation_from_third.key}
    end
  end
end