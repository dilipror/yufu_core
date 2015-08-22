require 'rails_helper'

RSpec.describe Support::Ticket, :type => :model do
  describe '.visible_for' do
    let(:user){create :user}
    let(:ticket_when_user_is_owner){create :ticket, user: user}
    let(:ticket_assigned_to_user){create :ticket, assigned_to: user}
    let(:other_ticket){create :ticket}
    
    before(:each){ticket_when_user_is_owner; ticket_assigned_to_user; other_ticket}    
    
    subject{Support::Ticket.visible_for(user)}
    
    it{is_expected.to include ticket_when_user_is_owner}
    it{is_expected.to include ticket_assigned_to_user}
    it{is_expected.not_to include other_ticket}
    
  end

  describe '#process' do
    let(:user){create :user}
    let(:ticket){create :ticket}

    subject{ticket.process user}

    it{expect{subject}.to change{ticket.reload.state}.to eq 'in_progress'}
    it{expect{subject}.to change{ticket.reload.assigned_to}.to eq user}
  end


  describe '#has_new_comments_for' do
    let(:ticket){create :ticket}
    let(:comment){create :comment, ticket: ticket}

    before(:each){comment}

    subject{ticket.has_new_comments_for? user}

    context 'user has new comment' do
      let(:user){ticket.user}

      it{is_expected.to be_truthy}
    end

    context 'user has not new comment' do
      let(:user){comment.author}

      it{is_expected.to be_falsey}
    end
  end
end
