require 'rails_helper'

RSpec.describe Withdrawal, :type => :model do
  describe '#execute' do
    let(:withdrawal){create :withdrawal, user: user}
    subject{withdrawal.execute}

    context 'user has enough balance' do
      let(:user){create :user, balance: 100000.0}

      it{expect{subject}.to change{Transaction.count}.by(1)}
      it{expect{subject}.to change{user.balance}.by(-100)}
      it{expect{subject}.to change{withdrawal.state}.to('executed')}
    end

    context 'user has not enough balance' do
      let(:user){create :user, balance: 0}

      it{expect{subject}.not_to change{Transaction.count}}
      it{expect{subject}.not_to change{user.balance}}
      it{expect{subject}.not_to change{withdrawal.state}}
    end
  end
end