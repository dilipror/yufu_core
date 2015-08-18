require 'rails_helper'

RSpec.describe Office do
  describe '.head' do
    subject{Office.head}

    context 'head office is present' do
      let(:head){create :office, head: true}
      before(:each) {head}

      it{is_expected.to eq head}
      it{expect{subject}.not_to change{Office.count}}
    end

    context 'head office is not present' do
      it{is_expected.to be_a Office}
      it{expect{subject}.to change{Office.count}.by(1)}
    end
  end
end