require 'rails_helper'

RSpec.describe Language, :type => :model do

  shared_context 'from and to services' do
    let(:lang_1){create :language}
    let(:lang_2){create :language}
    let(:lang_3){create :language}
    let(:lang_4){create :language}
    let(:lang_5){create :language}

    before(:each) do
      create :service, language: lang_1, written_approves: true, written_translate_type: 'From chinese'
      create :service, language: lang_2, written_approves: true, written_translate_type: 'From-to chinese'
      create :service, language: lang_3, written_approves: true, written_translate_type: 'To chinese'
      create :service, language: lang_4, written_approves: false
      create :service, language: lang_5, written_approves: true, written_translate_type: 'To chinese + corrector'
    end
  end

  describe '#available_from_chinese' do

    include_context 'from and to services'

    it 'expect count' do
      expect(Language.available_from_chinese.count).to eq(2)
    end

  end

  describe '#available_to_chinese' do

    include_context 'from and to services'

    it 'expect count' do
      expect(Language.available_to_chinese.count).to eq(3)
    end

  end

end
