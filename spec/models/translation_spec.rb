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


  describe  '#localize_model' do
    let(:language){create :language}
    let(:translation){create :translation, key: "Language.name.#{language.id}", is_model_localization: true}

    subject{translation.localize_model}

    it{expect{subject}.to change{language.reload.name}.to translation.value}
  end
end
