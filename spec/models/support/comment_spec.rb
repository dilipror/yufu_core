require 'rails_helper'

RSpec.describe Support::Comment, :type => :model do
  describe '.create' do
    let(:ticket) {create :ticket}
    let(:user)   {ticket.user}

    it {expect{create(:comment, ticket: ticket)}.to change{user.notifications.count}.by(1)}
  end

  describe '#viewed_by?' do
    let(:comment){create :comment, is_public: true}
    let(:user) {create :user}

    before(:each){receipt}

    subject{comment.viewed_by? user}

    context 'user has viewed receipt' do
      let(:receipt){create :support_comment_receipt, viewed: true, comment: comment, user: user}

      it{is_expected.to be_truthy}
    end


    context 'user has not viewed receipt' do
      let(:receipt){create :support_comment_receipt, viewed: false, comment: comment, user: user}

      it{is_expected.to be_falsey}
    end
  end
end
