require 'rails_helper'

RSpec.describe Order::Written::EventsService do

  shared_examples 'receive email' do
    it 'email should be sent' do
      subject
      expect(ActionMailer::Base.deliveries.count).to eq(2)
    end
  end
  let(:event_service) {Order::Written::EventsService.new order}

  let(:ch_lang) {create :language, is_chinese: true}
  let(:lang) {create :language}

  describe '#after_paid_order' do

    before(:each) do
      ActionMailer::Base.deliveries = []
    end


    subject{event_service.after_paid_order}

    context 'no translators with 5,6 hsk' do
      let!(:translator) {create :profile_translator,
                               services: [build(:service, written_approves: true, language: lang,
                                                written_translate_type: 'From-To Chinese')]}
      before(:each) {translator.profile_steps_service.update_attributes hsk_level: 4;
      translator.update_attributes state: 'approved'}

      context 'order not to ch' do
        let(:order) {create :order_written, original_language: ch_lang, translation_language: lang}
        include_examples 'receive email'
      end

      context 'no approved chinese translators' do
        let(:order) {create :order_written, original_language: lang, translation_language: ch_lang}
        include_examples 'receive email'
      end
    end

  end

  describe '#confirmation_order_in_30' do

    subject{event_service.confirmation_order_in_30}

    context 'when no assignee for 30 min' do
      context 'no translators with 5,6 hsk' do
        before(:each) {translator.profile_steps_service.update_attributes hsk_level: 4;
        translator.update_attributes state: 'approved'}

        let!(:translator) {create :profile_translator, state: 'approved',
                                  services: [build(:service, written_approves: true, language: lang,
                                                   written_translate_type: 'From-To Chinese')]}
        let(:order) {create :order_written, original_language: lang, translation_language: ch_lang}


        include_examples 'receive email'
      end
    end
  end

  describe '#after_translate_order' do
    subject{event_service.after_translate_order}

    context 'order to ch' do
      context 'translator is chinese' do
        let(:china) {create :country, is_china: true}
        let(:translator) {create :profile_translator}
        let(:order) {create :order_written, original_language: lang, translation_language: ch_lang,
                            assignee: translator}

        before(:each) {translator.profile_steps_language.update_attributes citizenship: china;
        allow(order).to receive(:cost).and_return(100)}

        it 'translator receive money' do
          subject
          expect(translator.user.balance).to eq 3
        end

      end

    end
  end
end
