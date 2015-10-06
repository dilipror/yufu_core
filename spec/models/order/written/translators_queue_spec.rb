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
      let(:user) do
        create :user, profile_translator: create(:profile_translator,
                                                 services: [build(:service, written_approves: true, language: org_lang,
                                                                  written_translate_type: 'To Chinese')])
      end
      let(:translator){user.profile_translator}
      let(:order){create :order_written, referral_link: user.referral_link, original_language: org_lang,
                         translation_language: chinese_lang}

      it_behaves_like 'queue builder'

      it{expect(subject.lock_to).to eq DateTime.now}
      it{expect(subject.translators).to include translator}
    end
  end

  describe '.create_chinese_translators_queue' do

    subject{Order::Written::TranslatorsQueue.create_chinese_translators_queue order}

    context 'pass nil' do
      let(:order) {nil}
      it{is_expected.to be_nil}
    end

    context 'original language is not chinese' do
      let(:order) {create :order_written, original_language: org_lang, translation_language: chinese_lang,
                          translation_type: 'From Chinese'}
      it{is_expected.to be_nil}
    end

    context 'no chinese translators' do

      let!(:user) do
        create :user, profile_translator: create(:profile_translator,
                                                 services: [build(:service, written_approves: true, language: org_lang,
                                                                  written_translate_type: 'To Chinese')])
      end
      let(:order) {create :order_written, original_language: org_lang, translation_language: chinese_lang,
                          translation_type: 'From Chinese'}
      # before(:each){Profile::Translator.stub(:chinese).and_return(nil)}
      # before(:each){allow(Profile::Translator).to receive(:chinese) { Profile::Translator.none }}

      it{is_expected.to be_nil}
    end

    context 'there are chinese translators' do
      let(:step_leng) {build :profile_steps_language, citizenship: create(:country, is_china: true)}

      let!(:user) do
        create :user, profile_translator: create(:profile_translator,
                                                 services: [build(:service, written_approves: true, language: org_lang,
                                                                  written_translate_type: 'To Chinese')])
      end
      let(:order) {create :order_written, original_language: org_lang, translation_language: chinese_lang,
                          translation_type: 'To Chinese'}

      it_behaves_like 'queue builder'

      it{expect(subject.lock_to).to eq DateTime.now}
      it{expect(subject.translators).to include translator}
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
        create :user, profile_translator: create(:profile_translator,
                                                 services: [build(:service, written_approves: true, language: org_lang,
                                                                  written_translate_type: 'To Chinese')])
      end
      let(:order) {create :order_written, original_language: org_lang, translation_language: chinese_lang,
                          translation_type: 'To Chinese'}

      it{is_expected.to be_nil}

    end

    context 'there are senior' do
      let!(:user) do
        create :user, profile_translator: create(:profile_translator,
                                                 services: [build(:service, written_approves: true, language: org_lang,
                                                                  written_translate_type: 'To Chinese')])
      end
      let(:order) {create :order_written, original_language: org_lang, translation_language: chinese_lang,
                          translation_type: 'To Chinese'}
      before(:each) {org_lang.update_attributes senior: user.profile_translator}

      it_behaves_like 'queue builder'

      it{expect(subject.lock_to).to eq DateTime.now}
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
        create :user, profile_translator: create(:profile_translator,
                                                 services: [build(:service, written_approves: true, language: org_lang,
                                                                  written_translate_type: 'To Chinese')])
      end
      let(:order) {create :order_written, original_language: org_lang, translation_language: chinese_lang,
                          translation_type: 'To Chinese'}

      it_behaves_like 'queue builder'

      it{expect(subject.lock_to).to eq DateTime.now}
      it{expect(subject.translators).to include user.profile_translator}
    end
  end
  #
  # describe '.create_senior_queue' do
  #   let(:city){create :city}
  #   let(:language){create :language}
  #   let!(:senior){create :profile_translator, city_approves: [build(:city_approve, is_approved: true, city: city)],
  #                        services: [build(:service, is_approved: true, language: language, level: 'guide')]}
  #   let(:private_translator) do
  #     create :user, profile_translator: create(:profile_translator,
  #                                              services: [build(:service, is_approved: true, language: language, level: 'guide')],
  #                                              city_approves: [build(:city_approve, is_approved: true, city: city)]
  #                 )
  #   end
  #   let(:order){create :wait_offers_order, location: city, language: language}
  #
  #   subject{Order::Verbal::TranslatorsQueue.create_senior_queue order}
  #
  #   before(:each){private_translator; language.update_attributes senior: senior}
  #
  #   it_behaves_like 'queue builder'
  #
  #   it{expect(subject.translators).to include senior}
  #   it{expect(subject.translators).not_to include private_translator.profile_translator}
  # end
  #
  # describe '.create_without_surcharge_queue' do
  #   let(:city){create :city}
  #   let(:language){create :language}
  #   let(:translator_1){create(:profile_translator,
  #                             services: [build(:service, is_approved: true, language: language, level: 'business')],
  #                             city_approves: [build(:city_approve, is_approved: true, city: city)] )}
  #
  #   let(:translator_2){create(:profile_translator,
  #                             services: [build(:service, is_approved: true, language: language, level: 'business')],
  #                             city_approves: [build(:city_approve, is_approved: true, city: city)] )}
  #
  #
  #   subject{Order::Verbal::TranslatorsQueue.create_without_surcharge_queue order}
  #
  #   before(:each) do
  #     Order::Verbal::TranslatorsQueue.create order_verbal: order, translators: [translator_1]
  #     translator_2
  #   end
  #
  #
  #   context 'low level order' do
  #     let(:order){create :wait_offers_order, location: city, language: language, level: 'business', include_near_city: false}
  #     it{expect(subject.translators).to include translator_2}
  #     it{expect(subject.translators).not_to include translator_1}
  #     it_behaves_like 'queue builder'
  #   end
  #
  #   context 'normal level order' do
  #     let(:order){create :wait_offers_order, location: city, language: language, level: 'guide', include_near_city: false}
  #     it{expect(subject.translators).to include translator_2}
  #     it{expect(subject.translators).not_to include translator_1}
  #     it_behaves_like 'queue builder'
  #   end

  # end
end
