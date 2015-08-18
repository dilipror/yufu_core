require 'rails_helper'

RSpec.describe LanguagesGroup, :type => :model do
  let(:languages_group) { create :languages_group }
  Currency.current_currency = 'CNY'
  describe '#verbal_cost' do
    context 'price with requested level exist' do
      it {expect(languages_group.verbal_cost('guide')).to eq(Price.without_markup languages_group.verbal_prices.first.value)}
    end
    context "price with requested level doesn't exist" do
      it {expect(languages_group.verbal_cost('fake')).to eq(BigDecimal.new('Infinity'))}
    end
  end

  describe '#written_cost' do
    context 'price with requested level exist' do
      it {expect(languages_group.written_cost('document')).to eq(Price.without_markup languages_group.written_prices.first.value)}
    end
    context "price with requested level doesn't exist" do
      it {expect(languages_group.written_cost('fake')).to eq(BigDecimal.new('Infinity'))}
    end
  end

end
