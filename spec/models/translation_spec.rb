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

  describe '.var_free' do
    let!(:translation_with_varabale){create :translation, value: 'text %{var}'}
    let!(:translation_without_varabale){create :translation, value: 'text'}

    subject{Translation.var_free}

    it{is_expected.to include translation_without_varabale}
    it{is_expected.not_to include translation_with_varabale}
  end

  describe '.tag_free' do
    let!(:translation_with_tag){create :translation, value: 'text <p>}'}
    let!(:translation_without_tag){create :translation, value: 'text'}

    subject{Translation.tag_free}

    it{is_expected.to include translation_without_tag}
    it{is_expected.not_to include translation_with_tag}
  end

  describe '.array_free' do
    let!(:translation_with_array){create :translation, value: 'text [var]'}
    let!(:translation_without_array){create :translation, value: 'text'}


    subject{Translation.array_free}

    it{is_expected.to include translation_without_array}
    it{is_expected.not_to include translation_with_array}
  end

  describe '.simple_text' do
    let!(:translation_with_simple_text){create :translation, value: 'text'}
    let!(:translation_with_tag){create :translation, value: 'text <p>}'}
    let!(:translation_with_array){create :translation, value: '["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]'}
    let!(:translation_with_varabale){create :translation, value: 'text %{var}'}

    subject{Translation.simple_texts}

    it{is_expected.to include translation_with_simple_text}
    it{is_expected.not_to include translation_with_varabale}
    it{is_expected.not_to include translation_with_tag}
    it{is_expected.not_to include translation_with_array}
  end


  describe '#only_authorised_attributes' do

    let(:translation){build :translation, attrs}

    subject{translation.valid?}

    context 'notificatoion key' do
      context 'all attribute in the list' do

        let(:attrs){{key: 'not_notification_mailer.some_meth.body', value: "%{client} %{root_url}"}}
        it{is_expected.to be_truthy}

      end
      context 'some attributes is not included' do

        let(:attrs){{key: 'not_notification_mailer.some_meth.body', value: "%{client} %{root}"}}
        it{is_expected.to be_truthy}

      end
    end

    context 'not notification key' do
      context 'all attribute in the list' do
        let(:attrs){{key: 'notification_mailer.some_meth.body', value: "%{client} %{root_url}"}}
        it{is_expected.to be_truthy}
      end
      context 'some attributes is not included' do
        let(:attrs){{key: 'notification_mailer.some_meth.body', value: "%{client} %{root}"}}
        it{is_expected.to be_falsey}
      end
    end
  end

  describe '#original' do
    let(:key) { 'key' }
    let(:original_localization){Localization.default}
    let(:approved_original_version) {create :localization_version, :approved, localization: original_localization}
    let!(:original_translation) {create :translation, version: approved_original_version, key: key, value: 'original'}
    let(:translation){create :translation, value: 'override', key: key}

    before(:each) {I18n.locale = original_localization.name}

    subject{translation.original}

    it{is_expected.to eq original_translation.value}
  end

  # describe  '#localize_model' do
  #   let(:language){create :language}
  #   let(:translation){create :translation, key: "Language.name.#{language.id}", is_model_localization: true}
  #
  #   before(:each){I18n.locale = translation.version.localization.name}
  #
  #   subject{translation.localize_model}
  #
  #   it{expect{subject}.to change{language.reload.name}.to translation.value}
  # end
end
