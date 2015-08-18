require 'rails_helper'

RSpec.describe Profile::Base, :type => :model do
  describe '#busy?' do
    let(:profile) {build :profile_translator, total_approve: true}
    subject{profile.busy? Date.today}
    it {is_expected.to be_falsey}
  end

  # метод, который нужно переписать
  # describe '#free_on' do
  #   let(:free_profile) {create :profile_translator, total_approve: true}
  #   let(:not_approved_profile) {create :profile_translator, total_approve: false}
  #   let(:translator_with_contract_on_day) {create :profile_translator, total_approve: true}
  #   before(:each) {free_profile && not_approved_profile && translator_with_contract_on_day}
  #
  #   subject{Profile::Translator.free_on Date.today}
  #
  #   it 'returns approved profiles without contracts on day' do
  #     is_expected.to include(free_profile)
  #   end
  #   it {is_expected.not_to include(not_approved_profile)}
  # end

  describe '#update' do
    let(:profile) {Profile::Base.create user: create(:user)}
    let(:user) {profile.user}

    it 'updates delegated attributes' do
      user.password = nil
      expect{profile.update first_name: 'name'}.to change{user.reload.first_name}.to('name')
    end
  end

end