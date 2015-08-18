require 'rails_helper'

RSpec.describe Statistic::Link do
  let(:user){create :user}
  let(:statistic) {Statistic::Link.new user}

  describe 'clicked' do
    before :each do
      user.referral_link.visits.create
    end

    describe '#clicked_count' do
      subject{statistic.clicked_count}
      it{is_expected.to eq 1}
    end

    describe '#clicked_persent' do
      subject{statistic.clicked_percent}
      it{is_expected.to eq nil}
    end
  end

  # describe 'pass_registration' do
  #   let(:pass_registration){create :invite, overlord: user}
  #   let(:vassal){create :user, email: pass_registration.email, invitation: pass_registration}
  #   let(:not_pass_registration){create :invite, overlord: user}
  #
  #   before(:each){vassal; not_pass_registration}
  #
  #   describe '#pass_registration_count' do
  #     subject{statistic.pass_registration_count}
  #     it{is_expected.to eq 1}
  #   end
  #
  #   describe '#pass_registration_persent' do
  #     subject{statistic.pass_registration_percent}
  #     it{is_expected.to eq 50}
  #   end
  # end
end