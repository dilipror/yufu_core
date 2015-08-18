require 'rails_helper'

describe Notification do
  describe '.create' do
    let(:user){create :user}
    subject{user.notifications.create options}
    context 'pass mailer' do
      let(:options){{mailer: -> (user, o) {PaymentsMailer.bank_payment user}}}

      it{expect{subject}.to change{PaymentsMailer.deliveries.count}.by(1)}
    end
    context 'does not pass mailer' do
      let(:options){{mailer: nil}}

      it{expect{subject}.to change{UsersMailer.deliveries.count}.by(1)}
    end
  end
end