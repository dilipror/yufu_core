require 'rails_helper'

RSpec.describe Order::LanguageCriterion, :type => :model do

  describe '#original_price' do

    subject{main_language.original_price}

    context 'should return price' do
      let(:main_language) {create :order_language_criterion}
      it {is_expected.to eq(1000)}
    end

    context 'should return 0' do
      let(:main_language) {create :order_language_criterion, language: nil}
      it {is_expected.to eq(0)}
    end

    context 'should return INFINITY' do
      let(:main_language) {create :order_language_criterion, level: 'business'}
      it {is_expected.to eq(BigDecimal::INFINITY)}
    end

  end

end