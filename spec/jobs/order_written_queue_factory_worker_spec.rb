require 'rails_helper'
RSpec.describe OrderWrittenQueueFactoryWorker, :type => :worker do

  let(:chinese_lang) {create :language, is_chinese: true}
  let(:org_lang) {create :language}
  let(:china) {create :country, is_china: true}

  let(:referral_link) {ReferralLink.create user: user}

  let(:order) {create :order_written, referral_link: referral_link, original_language: org_lang,
                     translation_language: chinese_lang}

  let!(:user) do
    create :user, profile_translator: create(:profile_translator,
                                             services: [build(:service, written_approves: true, language: org_lang,
                                                              written_translate_type: 'From-To Chinese')])
  end
  let!(:partner) {user.profile_translator}

  let!(:senior) {create(:profile_translator,
                        services: [build(:service, written_approves: true, language: org_lang,
                                         written_translate_type: 'From-To Chinese')])}

  let!(:chinese_transl) {create(:profile_translator,
                        services: [build(:service, written_approves: true, language: org_lang,
                                         written_translate_type: 'From-To Chinese')])}
  let!(:trans) {create(:profile_translator, passport_number: 2,
                       services: [build(:service, written_approves: true, language: org_lang,
                                        written_translate_type: 'From-To Chinese')])}

  before(:each) {org_lang.update_attributes senior: senior;
  chinese_transl.profile_steps_language.update_attribute :citizenship, china;chinese_transl.approve;
  partner.approve;senior.approve;trans.approve}

  describe 'perform' do
    subject{OrderWrittenQueueFactoryWorker.new.perform order.id, 'en'}

    it{expect{subject}.to change{order.reload.translators_queues.count}.by(4)}

    it{expect{subject}.to change{partner.reload.order_written_translators_queues.count}.by(1)}
    it{expect{subject}.to change{partner.reload.order_written_translators_queues.active.count}.by(1)}

    it{expect{subject}.to change{chinese_transl.reload.order_written_translators_queues.count}.by(1)}
    it{expect{subject}.to change{chinese_transl.reload.order_written_translators_queues.active.count}.by(0)}

    it{expect{subject}.to change{senior.reload.order_written_translators_queues.count}.by(1)}
    it{expect{subject}.to change{senior.reload.order_written_translators_queues.active.count}.by(0)}

    it{expect{subject}.to change{trans.reload.order_written_translators_queues.count}.by(1)}
    it{expect{subject}.to change{trans.reload.order_written_translators_queues.active.count}.by(0)}


  end

end
