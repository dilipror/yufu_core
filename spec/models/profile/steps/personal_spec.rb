require 'rails_helper'

RSpec.describe Profile::Steps::Personal do
  describe 'update delegated fields' do
    let(:personal_step) {create :profile_steps_personal}
    let(:user) {personal_step.translator.user}

    before(:each) {user.password = user.password_confirmation = nil }

    subject{personal_step.update first_name: 'new first name'}

    # it {expect{subject}.to change{user.reload.first_name}.to('new first name')}
    it {expect{subject}.to change{user.first_name}.to('new first name')}
  end
end