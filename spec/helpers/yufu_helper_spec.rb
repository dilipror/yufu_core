require 'rails_helper'

describe YufuHelper type: :helper do
  describe '.mail_with_params' do
    before(:each) {I18n.stub(:t).with(anything()).and_return('some text #param_1')}


    subject(helper.mail_with_params('key', ['PARAM HERE']))

    it {is_expected.to eq('some text PARAM HERE')}
  end
end