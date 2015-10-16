require 'rails_helper'

RSpec.describe Order::Written::EventsService do

  # shared_examples 'receive email' do
  #   it 'email should be sent' do
  #     subject
  #     expect(ActionMailer::Base.deliveries.count).to eq(2)
  #   end
  # end
  let(:event_service) {Order::Written::EventsService.new order}
  #
  let(:ch_lang) {create :language, is_chinese: true}
  let(:lang) {create :language}
  #
  # describe '#after_paid_order' do
  #
  #   before(:each) do
  #     ActionMailer::Base.deliveries = []
  #   end
  #
  #
  #   subject{event_service.after_paid_order}
  #
  #   context 'no translators with 5,6 hsk' do
  #     let!(:translator) {create :profile_translator,
  #                              services: [build(:service, written_approves: true, language: lang,
  #                                               written_translate_type: 'From-To Chinese')]}
  #     before(:each) {translator.profile_steps_service.update_attributes hsk_level: 4;
  #     translator.update_attributes state: 'approved'}
  #
  #     context 'order not to ch' do
  #       let(:order) {create :order_written, original_language: ch_lang, translation_language: lang}
  #       include_examples 'receive email'
  #     end
  #
  #     context 'no approved chinese translators' do
  #       let(:order) {create :order_written, original_language: lang, translation_language: ch_lang}
  #       include_examples 'receive email'
  #     end
  #   end
  #
  # end

  # describe '#confirmation_order_in_30' do
  #
  #   subject{event_service.confirmation_order_in_30}
  #
  #   context 'when no assignee for 30 min' do
  #     context 'no translators with 5,6 hsk' do
  #       before(:each) {translator.profile_steps_service.update_attributes hsk_level: 4;
  #       translator.update_attributes state: 'approved'}
  #
  #       let!(:translator) {create :profile_translator, state: 'approved',
  #                                 services: [build(:service, written_approves: true, language: lang,
  #                                                  written_translate_type: 'From-To Chinese')]}
  #       let(:order) {create :order_written, original_language: lang, translation_language: ch_lang}
  #
  #
  #       include_examples 'receive email'
  #     end
  #   end
  # end

  describe '#after_translate_order' do
    subject{event_service.after_translate_order}

    let!(:theme) {Support::Theme.create name: 'lol', theme_type: :order_written}

    context 'order to ch' do
      context 'translator is chinese' do
        context 'need proofreadin' do
          let(:china) {create :country, is_china: true}
          let(:translator) {create :profile_translator}
          let(:order) {create :order_written, original_language: lang, translation_language: ch_lang,
                              assignee: translator, translation_type: 'translate_and_correct'}
          before(:each) {translator.profile_steps_language.update_attribute :citizenship, china}

          it{expect{subject}.to change{Support::Ticket.count}.by 1}
        end

      end
      context 'translator not chinese' do
        let(:translator) {create :profile_translator}
        let(:order) {create :order_written, original_language: lang, translation_language: ch_lang,
                            assignee: translator, translation_type: 'translate_and_correct'}

        it{expect{subject}.to change{Support::Ticket.count}.by 1}
      end
    end

    context 'order from ch' do
      context 'order need proof read' do
        # context 'assignee can proof read' do
        #   let(:order) {create :order_written, original_language: ch_lang, translation_language: lang,
        #                       assignee: trans, translation_type: 'translate_and_correct', state: 'in_progress'}
        #   let!(:trans) {create(:profile_translator,
        #                                 services: [build(:service, written_approves: true, language: lang,
        #                                                  written_translate_type: 'From Chinese + Corrector')])}
        #   it 'assign translator as proof reader' do
        #     subject
        #     expect(order.proof_reader).to eq trans
        #     expect(order.state).to eq 'correcting'
        #   end
        # end

        context 'assignee cant proof read' do
          let(:order) {create :order_written, original_language: ch_lang, translation_language: lang,
                              assignee: trans, translation_type: 'translate_and_correct', state: 'wait_corrector'}
          let!(:trans) {create(:profile_translator,
                               services: [build(:service, written_approves: true, language: lang,
                                                written_translate_type: 'From Chinese')])}
          it 'order wait corrector' do
            subject
            expect(order.state).to eq 'wait_corrector'
          end
        end
      end

      # context 'order dont need proof read' do
      #   let(:order) {create :order_written, original_language: ch_lang, translation_language: lang,
      #                       assignee: trans, translation_type: 'translate', state: 'in_progress'}
      #   let(:trans) {create(:profile_translator,
      #                        services: [build(:service, written_approves: true, language: lang,
      #                                         written_translate_type: 'From Chinese')])}
      #   it 'order transition to quality_control' do
      #     subject
      #     expect(order.state).to eq 'quality_control'
      #   end
      # end

    end
  end
end
