require 'rails_helper'

RSpec.describe BlankLocalizedFields do
  before :all do
    class ExampleClass2
      include Mongoid::Document
      include BlankLocalizedFields

      field :name, localize: true
      clear_localized :name

      validates_presence_of :name
    end
  end

  describe 'after validation' do
    let(:object) do
      o = ExampleClass2.new
      o.name_translations = translations
      o
    end

    subject{object.valid?}

    context 'blank value not for current locale' do
      let(:translations){ {en: 'foo', ru: ''} }
      it{is_expected.to be_truthy}
    end

    context 'blank value for current locale' do
      let(:translations){ {en: '', ru: 'bar'} }
      it{is_expected.to be_falsey}
    end
  end
end