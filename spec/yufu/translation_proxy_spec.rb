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
end