require 'rails_helper'

describe Localization do
  describe '.get_translations_hash' do
    let!(:localization){create :localization}
    let!(:version){create :localization_version, :approved, localization: localization}

    let!(:translation_1){create :translation, key: 'example.one', version: version}
    let!(:translation_2){create :translation, key: 'example.two', version: version}
    let!(:translation_3){create :translation, key: 'example.three.nested', version: version}

    let(:expected_hash) do
      {
        example: {
          one: translation_1.value,
          two: translation_2.value,
          three: {nested: translation_3.value}
        }
      }
    end

    subject{localization.get_translations_hash}

    it { is_expected.to eq expected_hash }
  end
end