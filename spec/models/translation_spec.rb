require 'rails_helper'

RSpec.describe Translation, :type => :model do

  describe 'sanitize value' do
    let(:unsafe_html){'<p>good</p><script>script content</script>'}
    let(:translation) {create :translation, value: unsafe_html}

    subject{translation.value}

    it{is_expected.to include '<p>good</p>'}
    it{is_expected.not_to include '<script>script content</script>'}
    it{is_expected.not_to include 'script content'}
  end


  describe  '#localize_model' do
    let(:language){create :language}
    let(:translation){create :translation, key: "Language.name.#{language.id}", is_model_localization: true}

    subject{translation.localize_model}

    it{expect{subject}.to change{language.reload.name}.to translation.value}
  end

  describe 'wear_out previous translation by key  in localization' do
    let(:localization){create :localization}
    let(:current_version){create :localization_version, localization: localization}
    let(:previous_version){create :localization_version, localization: localization}
    let(:translation_in_previous_version){create :translation, key: 'key', version: previous_version}
    let(:translation_with_other_key){create :translation, key: 'other', version: previous_version}
    let(:version_in_other_locale){create :localization_version}
    let(:translation_in_other_version){create :translation, key: 'key', version: version_in_other_locale}
    let(:new_translation){Translation.new(key: 'key', version: current_version)}

    before(:each){Localization.destroy_all; I18n.locale = :en }

    subject{new_translation.save}

    context 'has not next version' do
      before(:each) do
        translation_in_previous_version; new_translation; translation_with_other_key; translation_in_other_version
      end
      it{expect{subject}.to change{translation_in_previous_version.reload.next}.to(new_translation)}
      it{expect{subject}.not_to change{translation_with_other_key.reload.next}}
      it{expect{subject}.not_to change{translation_in_other_version.reload.next}}
      it{expect{subject}.not_to change{new_translation.next}}
    end

    context 'has next version' do
      let(:next_version){create :localization_version, localization: localization}
      let(:translation_in_next_version){create :translation, key: 'key', version: next_version}
      before(:each) do
        translation_in_previous_version; new_translation; translation_with_other_key; translation_in_other_version; translation_in_next_version
      end
      before(:each){translation_in_next_version}
      it{expect{subject}.not_to change{translation_in_next_version.reload.next}}
    end

  end
end
