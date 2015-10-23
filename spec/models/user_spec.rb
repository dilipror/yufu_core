require 'rails_helper'

RSpec.describe User, :type => :model do

  describe '#authorized_translator?' do
    let(:user) {create :translator}

    before(:each) do
      user.profile_translator.services << create(:service)
    end

    subject{user.authorized_translator?}

    context 'all services and cities are not approved' do
      it {is_expected.to be_falsey}
    end

    context 'one service is approved but all cities are not approved' do
      before(:each) {user.profile_translator.services.first.update is_approved: true}
      it {is_expected.to be_falsey}
    end

    context "translator has an approved cities but has'not an approved services" do
      before(:each){CityApprove.create city: create(:city), translator: user.profile_translator}
      it {is_expected.to be_falsey}
    end
    context 'translator has an approved cities and has an approved services' do
      before(:each) do
        CityApprove.create city: create(:city), translator: user.profile_translator, is_approved: true
        user.profile_translator.services.first.update is_approved: true
      end
      it {is_expected.to be_truthy}
    end
  end

  describe '#create_banners' do
    let(:user){create :user, banners: []}

    it 'expect banners' do
      expect(user.banners.length).to eq(3)
    end
  end

  describe 'invites to user not come from link' do

    subject{user.invitation}

    let(:email){'email@example.com'}

    let(:user){create :user, invitation: invite, email: email}

    context 'invite expired' do

      before(:each){create :invite, email: email, expired: true}

      let(:invite){nil}

      it{is_expected.to be_nil}

    end

    context 'invite not expired' do

      let(:new_invite){ create :invite, email: email, expired: false}

      before(:each){new_invite}

      let(:invite){nil}

      it{is_expected.to eq(new_invite)}

    end

    context 'has already invite' do

      before(:each){create :invite, email: email, expired: true}

      let(:invite){create :invite, email: email}

      it{is_expected.to eq(invite)}

    end

  end

  # describe 'update password'  do
  #   let(:user) {User.first}
  #
  #   before(:each) {create :user, password: 'password'}
  #
  #   subject {user.password = new_password}
  #
  #   context 'new password equals old' do
  #     let(:new_password) {'password'}
  #     it {expect{subject}.to change{user.valid?}.from(true).to(false)}
  #   end
  #
  #   context 'new password equals old' do
  #     let(:new_password) {'new_password'}
  #     it {expect{subject}.not_to change{user.valid?}}
  #   end
  # end

  describe '#promoted_get?' do
    let(:user){create :user}
    subject{user.promoted_get? order}

    context 'user is owner of referal link' do
      let(:order){create :order_base, referral_link: user.referral_link}

      it{is_expected.to be_truthy}
    end

    context 'user is owner of banner' do
      let(:order){create :order_base, banner: user.banners.first}

      it{is_expected.to be_truthy}
    end

    context "user is overlord of link's owner" do
      let(:vassal){create :user, overlord: user}
      let(:order){create :order_base, referral_link: vassal.referral_link}

      it{is_expected.to be_truthy}
    end

    context "user is overlord of banner's owner" do
      let(:vassal){create :user, overlord: user}
      let(:order){create :order_base, banner: vassal.referral_link}

      it{is_expected.to be_truthy}
    end

    context "user is overlord of order's owner" do
      let(:vassal){create :user, overlord: user}
      let(:order){create :order_base, owner: vassal}

      it{is_expected.to be_truthy}
    end

    context 'other' do
      let(:order){create :order_base}
      it{is_expected.to be_falsey}
    end
  end

  describe 'can change role' do
    let(:user){create :user, role: 'translator', sign_in_count: 10}

    subject{user.can_change_role?}


    context 'right after change' do

      before(:each) do
        user.update role: 'client'
      end

      it {is_expected.to be_falsey}
    end

    context '24 hours later' do

      before(:each) do
        user.update role: 'client'
        Delorean.jump(25.hours)
      end

      it {is_expected.to be_truthy}
    end

    context 'first time' do
      it {is_expected.to be_truthy}
    end
  end

  describe '#full_name' do
    subject {user.full_name}
    context 'first name and last name is presented' do
      let(:user){create :user, first_name: 'Ruby', last_name: 'Rails'}
      it {is_expected.to eq 'Ruby Rails'}
    end

    context  'first name and last name is not presented' do
      let(:user){create :user, first_name: nil, last_name: nil}
      it {is_expected.to eq user.email}
    end
  end

  describe '#set_overlord' do
    subject{user}

    context 'create with invitation' do
      let(:invite) {create :invite}
      let(:user) {create :user, invitation: invite}

      it{expect(user.overlord).to eq(invite.overlord)}
    end

    context 'create without invitation' do
      let(:user) {create :user}

      it{expect(user.overlord).to be_nil}
    end
  end

  describe 'creation default invitation text' do
    let(:user) {build :user}
    subject{user.save}
    it 'invitation texts should be created' do
      subject
      expect(user.invitation_texts.count).to eq 3
    end
  end
end
