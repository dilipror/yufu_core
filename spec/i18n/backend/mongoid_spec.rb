require 'rails_helper'

RSpec.describe I18n::Backend::Mongoid do
  describe '#lookup' do

    let(:localization){Localization.default}
    let(:locale){localization.name}
    let(:key){'key'}
    let(:older_approved_version)  {create :localization_version, :approved, localization: localization}
    let(:current_approved_version){create :localization_version, :approved, localization: localization}
    let(:not_approved_version){create :localization_version, localization: localization}
    let(:translation_in_not_approved_version){Translation.create key: key, version: not_approved_version, value: 'new'}

    before(:each){older_approved_version; current_approved_version; current_approved_version; translation_in_not_approved_version}
    subject{I18n::Backend::Mongoid.new.send(:lookup, locale, key)}

    context 'translation is override on a new version' do
      let(:translation_in_new_version){Translation.create key: key, version: current_approved_version, value: 'new'}
      let(:translation_in_old_version){Translation.create key: key, version: older_approved_version, value: 'new'}

      before(:each){translation_in_new_version; translation_in_old_version}

      it{is_expected.to eq translation_in_new_version.value}
    end

    context 'translation is override on a new version' do
      let(:translation_in_old_version){Translation.create key: key, version: older_approved_version, value: 'new'}

      before(:each){translation_in_old_version}

      it{is_expected.to eq translation_in_old_version.value}
    end
  end

  describe 'I18n.t' do
    let(:localization){Localization.default}
    let(:locale){localization.name}
    let(:key){'key'}
    let(:version)  {create :localization_version, :approved, localization: localization}
    let(:translation){Translation.create key: key, version: version, value: 'value'}

    before :each do
      translation
      I18n.backend = I18n::Backend::Chain.new(I18n::Backend::Mongoid.new, I18n.backend)
    end

    subject{I18n.t key}

    it{is_expected.to eq translation.value}
  end
end