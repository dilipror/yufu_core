require 'rails_helper'

RSpec.describe Order::Written::CorrectorsQueue, :type => :model do

  RSpec.shared_examples 'queue builder' do
    it{is_expected.to be_a Order::Written::CorrectorsQueue}
    it{expect{subject}.to change{order.reload.correctors_queues.count}.by(1)}
  end

  let(:chinese_lang) {create :language, is_chinese: true}
  let(:org_lang) {create :language}

  describe '.create_partner_queue' do
    subject{Order::Written::CorrectorsQueue.create_partner_queue order}

    context 'pass nil' do
      let(:order){nil}

      it{is_expected.to be_nil}
    end

    context 'order has not agents' do
      let(:order){create :order_written}

      it{is_expected.to be_nil}
    end

    context 'agent does not support order' do
      let(:order){create :order_written, referral_link: create(:user).referral_link}

      it{is_expected.to be_nil}
    end

    context 'agent support order' do
      let(:org_lang){create :language}
      let!(:user) do
        create :user, profile_translator: create(:profile_translator,
                                                 services: [build(:service, written_approves: true, language: org_lang,
                                                                  written_translate_type: 'From Chinese + Corrector')])
      end
      let(:order){create :order_written, referral_link: user.referral_link, original_language: org_lang,
                         translation_language: chinese_lang}

      it_behaves_like 'queue builder'

      it{expect(subject.lock_to).to be_within(1.second).of DateTime.now}
      it{expect(subject.translators).to include user.profile_translator}
    end
  end

  describe '.create_senior_queue' do
    subject{Order::Written::CorrectorsQueue.create_senior_queue order}

    context 'pass nil' do
      let(:order) {nil}
      it{is_expected.to be_nil}
    end

    context 'language has not senior' do
      let!(:user) do
        create :user, profile_translator: create(:profile_translator,
                                                 services: [build(:service, written_approves: true, language: org_lang,
                                                                  written_translate_type: 'From Chinese + Corrector')])
      end
      let(:order) {create :order_written, original_language: org_lang, translation_language: chinese_lang,
                          translation_type: 'To Chinese'}

      it{is_expected.to be_nil}

    end

    context 'there are senior' do
      let!(:user) do
        create :user, profile_translator: create(:profile_translator,
                                                 services: [build(:service, written_approves: true, language: org_lang,
                                                                  written_translate_type: 'From Chinese + Corrector')])
      end
      let(:order) {create :order_written, original_language: org_lang, translation_language: chinese_lang,
                          translation_type: 'To Chinese'}
      before(:each) {org_lang.update_attributes senior: user.profile_translator}

      it_behaves_like 'queue builder'

      it{expect(subject.lock_to).to eq DateTime.now}
      it{expect(subject.translators).to include user.profile_translator}
    end
  end

  describe '.create_other_correctors_queue' do
    subject{Order::Written::CorrectorsQueue.create_other_correctors_queue order}

    context 'pass nil' do
      let(:order) {nil}
      it{is_expected.to be_nil}
    end

    context 'there are other translators' do
      let!(:user) do
        create :user, profile_translator: create(:profile_translator, state: 'ready_for_approvement',
                                                 services: [build(:service, written_approves: true, language: org_lang,
                                                                  written_translate_type: 'From Chinese + Corrector')])
      end
      let(:order) {create :order_written, original_language: chinese_lang, translation_language: org_lang,
                          translation_type: 'From Chinese'}

      before(:each) {user.profile_translator.approve}

      it_behaves_like 'queue builder'

      it{expect(subject.lock_to).to eq DateTime.now}
      it{expect(subject.translators).to include user.profile_translator}
    end
  end
end
