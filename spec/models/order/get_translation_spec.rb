require 'rails_helper'

RSpec.describe Order::GetTranslation, type: :model do
  describe 'validate email' do
    subject{order.valid?}

    context 'email is empty' do
      let(:order){create(:order_written) }
      it {expect(subject).to be_truthy}
    end

    context 'valid' do
      let(:order){order = create(:order_written);order.get_translation.update email: 'email@example.com'; order }
      it {expect(subject).to be_truthy}
    end

    context  'invalid' do
      let(:order){order = create(:order_written);order.get_translation.update email: 'emailcom'; order }
      it {expect(subject).to be_falsey}
    end
  end
end