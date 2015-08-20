require 'rails_helper'

RSpec.describe Translation, :type => :model do

  describe  '#localize_model' do
    let(:language){create :language}
    let(:translation){create :translation, key: "Language.name.#{language.id}", is_model_localization: true}

    subject{translation.localize_model}

    it{expect{subject}.to change{language.reload.name}.to translation.value}
  end

end
