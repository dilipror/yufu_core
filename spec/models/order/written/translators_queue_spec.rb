require 'rails_helper'

RSpec.describe Order::Written::TranslatorsQueue, :type => :model do

  RSpec.shared_examples 'queue builder' do
    it{is_expected.to be_a Order::Written::TranslatorsQueue}
    it{expect{subject}.to change{order.reload.translators_queues.count}.by(1)}
  end

  let(:chinese_lang) {create :language, is_chinese: true}
  let(:org_lang) {create :language}

  describe '.create_partner_queue' do
    subject{Order::Written::TranslatorsQueue.create_partner_queue order}

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
                                                                  written_translate_type: 'To Chinese')])
      end
      let(:order){create :order_written, referral_link: user.referral_link, original_language: org_lang,
                         translation_language: chinese_lang}

      it_behaves_like 'queue builder'

      it{expect(subject.lock_to).to be_within(1.second).of DateTime.now}
      it{expect(subject.translators).to include user.profile_translator}
    end
  end

  describe '.create_chinese_translators_queue' do

    subject{Order::Written::TranslatorsQueue.create_chinese_translators_queue order}

    context 'pass nil' do
      let(:order) {nil}
      it{is_expected.to be_nil}
    end

    context 'translation language is not chinese' do
      let(:order) {create :order_written, original_language: chinese_lang, translation_language: org_lang,
                          translation_type: 'To Chinese'}
      it{is_expected.to be_nil}
    end

    context 'no chinese translators' do

      let!(:user) do
        create :user, profile_translator: create(:profile_translator,
                                                 services: [build(:service, written_approves: true, language: org_lang,
                                                                  written_translate_type: 'To Chinese')])
      end
      let(:order) {create :order_written, original_language: org_lang, translation_language: chinese_lang,
                          translation_type: 'To Chinese'}
      # before(:each){Profile::Translator.stub(:chinese).and_return(nil)}
      # before(:each){allow(Profile::Translator).to receive(:chinese) { Profile::Translator.none }}

      it{is_expected.to be_nil}
    end

    context 'there are chinese translators' do
      let(:china) {create :country, is_china: true}

      let!(:user) do
        create :user, profile_translator: create(:profile_translator, :approving_in_progress,
                                                 services: [build(:service, written_approves: true, language: org_lang,
                                                                  written_translate_type: 'To Chinese')])
      end
      let(:order) {create :order_written, original_language: org_lang, translation_language: chinese_lang,
                          translation_type: 'To Chinese'}

      before(:each) {user.profile_translator.profile_steps_language.update_attribute :citizenship, china;
      user.profile_translator.approve}

      it_behaves_like 'queue builder'

      it{expect(subject.lock_to).to be_within(1.second).of DateTime.now}
      it{expect(subject.translators).to include user.profile_translator}
    end
  end

  describe '.create_senior_queue' do
    subject{Order::Written::TranslatorsQueue.create_senior_queue order}

    context 'pass nil' do
      let(:order) {nil}
      it{is_expected.to be_nil}
    end

    context 'language has not senior' do
      let!(:user) do
        create :user, profile_translator: create(:profile_translator, :approving_in_progress,
                                                 services: [build(:service, written_approves: true, language: org_lang,
                                                                  written_translate_type: 'To Chinese')])
      end
      let(:order) {create :order_written, original_language: org_lang, translation_language: chinese_lang,
                          translation_type: 'To Chinese'}

      it{is_expected.to be_nil}

    end

    context 'there are senior' do
      let!(:user) do
        create :user, profile_translator: create(:profile_translator, :approving_in_progress,
                                                 services: [build(:service, written_approves: true, language: org_lang,
                                                                  written_translate_type: 'To Chinese')])
      end
      let(:order) {create :order_written, original_language: org_lang, translation_language: chinese_lang,
                          translation_type: 'To Chinese'}
      before(:each) {org_lang.update_attributes senior: user.profile_translator}

      it_behaves_like 'queue builder'

      it{expect(subject.lock_to).to be_within(1.second).of DateTime.now}
      it{expect(subject.translators).to include user.profile_translator}
    end
  end

  describe '.create_other_translators_queue' do
    subject{Order::Written::TranslatorsQueue.create_other_translators_queue order}

    context 'pass nil' do
      let(:order) {nil}
      it{is_expected.to be_nil}
    end

    context 'there are other translators' do
      let!(:user) do
        create :user, profile_translator: create(:profile_translator, :approving_in_progress,
                                                 services: [build(:service, written_approves: true, language: org_lang,
                                                                  written_translate_type: 'To Chinese')])
      end
      let(:order) {create :order_written, original_language: org_lang, translation_language: chinese_lang,
                          translation_type: 'To Chinese'}

      before(:each) {user.profile_translator.approve}

      it_behaves_like 'queue builder'

      it{expect(subject.lock_to).to be_within(1.second).of DateTime.now}
      it{expect(subject.translators).to include user.profile_translator}
    end
  end
end
