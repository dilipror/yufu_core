require 'rails_helper'

describe Notification do
  describe '.create' do
    let!(:user){create :user}
    let!(:order){create :order_verbal}
    subject{user.notifications.create options }
    context 'pass mailer' do
      let(:options){{mailer: -> (user, o) {PaymentsMailer.bank_payment user}, user: user, object: order}}

      it{expect{subject}.to change{user.reload.notifications.count}.by(1)}
    end
    context 'does not pass mailer' do
      let(:options){{mailer: nil}}

      it{expect{subject}.to change{user.reload.notifications.count}.by(1)}
    end
  end
end