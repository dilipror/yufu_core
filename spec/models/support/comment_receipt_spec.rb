require 'rails_helper'

RSpec.describe Support::CommentReceipt, :type => :model do
  describe 'create receipt after create' do
    let(:ticket){create :ticket}
    let(:author){create :user}

    subject{create :comment, ticket: ticket, author: author}

    it{expect{subject}.to change{Support::CommentReceipt.count}.by(2)}

    it 'creates viewed receipt fot author' do
      expect(subject.comment_receipts.where(user: author).first.viewed?).to be_truthy
    end

    it 'creates not viewed receipt for owner' do
      expect(subject.comment_receipts.where(user: ticket.user).first.viewed?).to be_falsey
    end
  end
end
