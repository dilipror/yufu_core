require 'rails_helper'

RSpec.describe Price::Base, :type => :model do

  let(:price) {build :price_base}
  Currency.current_currency = 'CNY'

  describe "#value=" do
    subject {price.update_attribute :value, 100}

    it 'expect value' do
      expect{subject}.to change{price.value}.to(100)
    end
  end
end
