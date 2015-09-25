require 'rails_helper'

RSpec.describe Transaction, :type => :model do
  describe 'cancel' do
    let(:debit) {transaction.debit}
    let(:credit){transaction.credit}

    subject{ transaction.cancel }

    context 'cancel new transaction' do
      let(:transaction) {create :transaction}
      it { expect{subject}.not_to change{debit.reload.balance} }
      it { expect{subject}.not_to change{credit.reload.balance} }
      it { expect{subject}.to change{transaction.canceled?}.to(true)}
    end

    context 'cancel executed transaction' do
      let(:transaction) {create :transaction, state: :executed}
      it { expect{subject}.to change{credit.reload.balance}.by(-transaction.sum) }
      it { expect{subject}.to change{debit.reload.balance}.by(transaction.sum) }
      it { expect{subject}.to change{transaction.canceled?}.to(true)}
    end

    context 'double cancel' do
      let(:transaction) {create :transaction, state: :canceled}
      it { expect{subject}.not_to change{debit.reload.balance} }
      it { expect{subject}.not_to change{credit.reload.balance} }
    end
  end

  describe 'execute' do
    let(:debit) {transaction.debit}
    let(:credit){transaction.credit}

    subject{ transaction.execute }

    RSpec.shared_examples 'execute checks' do
      it { expect{subject}.to change{debit.reload.balance}.by(-transaction.sum) }
      it { expect{subject}.to change{credit.reload.balance}.by(transaction.sum) }
      it { expect{subject}.to change{transaction.executed?}.to(true)}
    end

    context 'execute new transaction' do
      let(:transaction) {create :transaction}
      include_examples 'execute checks'
    end

    context 'execute rejected transaction' do
      let(:transaction) {create :transaction, state: :canceled}
      include_examples 'execute checks'
    end

    context 'double execute' do
      let(:transaction) {create :transaction, state: :executed}
      it { expect{subject}.not_to change{debit.reload.balance} }
      it { expect{subject}.not_to change{credit.reload.balance} }
    end
  end

  describe '.active' do
    let(:localization) {create :localization}
    let(:key){'key'}
    let!(:old_approved_version){create :localization_version, :approved, localization: localization}
    let!(:last_approved_version){create :localization_version, :approved, localization: localization}
    let!(:last_not_approved_version){create :localization_version, localization: localization}
    let!(:old_approved_translation){create :translation, key: key, version: old_approved_version}
    let!(:last_approved_translation){create :translation, key: key, version: last_approved_version}
    let!(:last_not_approved_translation){create :translation, key: key, version: last_not_approved_version}

    subject{Translation.active}

    it{is_expected.to include last_approved_translation}
    it{is_expected.not_to include old_approved_translation}
    it{is_expected.not_to include last_not_approved_translation}

  end
end
