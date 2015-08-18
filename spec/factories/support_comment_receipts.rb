FactoryGirl.define do
  factory :support_comment_receipt, :class => 'Support::CommentReceipt' do
    association :comment
    association :user
  end

end
