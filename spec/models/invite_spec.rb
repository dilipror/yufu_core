require 'rails_helper'

RSpec.describe Invite, :type => :model do

  describe 'only_one_invite_until_expired' do

    let(:user1){create :user}
    let(:user2){create :user}

    subject{build(:invite, email: 'email@example.com', overlord: user1).valid?}

    context 'no invite' do
      it{is_expected.to be_truthy}
    end

    context 'invite not expired' do

      before(:each){create :invite, email: 'email@example.com', expired: false, overlord: user2}

      it{is_expected.to be_falsey}

    end

    context 'invite expired' do
      before(:each){create :invite, email: 'email@example.com', expired: true, overlord: user2}

      it{is_expected.to be_truthy}

    end

  end
  context 'not case sensetive validation' do

    before(:each){create :invite, email: 'email@example.com'}

    subject{build(:invite, email: 'EMAIL@EXAMPLE.COM').valid?}

    it {is_expected.to be_falsey}

  end

  context 'uderscore email' do
    let(:invite){create :invite, email: 'Camel@Case.Com'}

    subject{invite.email}

    it{is_expected.to eq('camel@case.com')}
  end

  describe 'uniq_email_in_registered_users' do

    context 'user exists' do

      let(:user){create :user}

      subject{build(:invite, email: user.email).valid?}

      it{is_expected.to be_falsey}
    end

    context 'user is vassal' do
      let(:user){create :user}

      subject{build(:invite, email: user.email, vassal: user).valid?}

      it{is_expected.to be_truthy}
    end

    context 'user does not exist' do
      subject{build(:invite, email: 'vasya@pup.king').valid?}

      it{is_expected.to be_truthy}
    end

  end

end
