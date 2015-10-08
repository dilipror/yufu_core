require 'rails_helper'

RSpec.describe Order::Written, type: :model do

  Currency.current_currency = 'CNY'
  let(:lang){create :language}
  let(:order){create :order_written, order_type: lang.languages_group.written_prices.first.written_type,
                     translation_language: lang}
  let(:order_correction){create :order_written, translation_type: 'translate_and_correct'}


  # let(:languages_groups){create :languages_group}
  describe '#original_price' do

    before(:each) do
      ExchangeBank.update_rates
    end

    let(:language){create :language}
    let(:chinese){create :language, is_chinese: true}
    let(:order){create :order_written, state: :new, translation_type: 'translate',
                       original_language: language, translation_language: chinese,
                       order_type: language.languages_group.written_prices.last.written_type}

    subject{order.original_price}
    it{is_expected.to be_a BigDecimal}
    it{is_expected.to eq order.quantity_for_translate * language.languages_group.written_prices.first.value}

    context 'when get_original post' do
      let(:order){create :order_written, state: :new, translation_type: 'translate',
                         original_language: language, translation_language: chinese,
                         order_type: language.languages_group.written_prices.last.written_type}
      before(:each) {order.get_original.update_attributes(send_type: 'post', name: 'd', address: 's', index: '1')}

      it{is_expected.to eq order.quantity_for_translate * language.languages_group.written_prices.first.value + Order::Written.surcharge_for_postage}
    end
  end

  describe '#base_lang_cost' do

    before (:each) do
      Price::Written.any_instance.stub(:value).and_return(1000)
      Price::Written.any_instance.stub(:value_ch).and_return(800)
      order.original_language.stub(:is_hieroglyph).and_return(is_hieroglyph)
    end

    context 'original is chinese' do

      let(:is_hieroglyph){true}

      before(:each){order.stub(:count_on_words?).and_return(true)}

      it 'return base lang price' do
        expect(order.base_lang_cost(lang)).to eq(800)
      end

    end

    context 'original is not chinese' do

      let(:is_hieroglyph){false}

      it 'return base lang price' do
        expect(order.base_lang_cost(lang)).to eq(1000)
      end

    end
  end

  describe '#lang_price' do

    before(:each){order.stub(:count_on_words?).and_return(true)}

    before(:each) do
      ExchangeBank.update_rates
    end
    context 'cases' do
      before(:each) do
        order.stub(:quantity_for_translate).and_return(words_count)
        order.original_language.stub(:is_hieroglyph).and_return(is_hieroglyph)
      end

      subject{order.lang_price(lang)}

      context 'document translation' do

        before(:each){order.stub(:count_on_words?).and_return(false)}

        let(:words_count){1}
        let(:is_hieroglyph){true}

        it {is_expected.to eq(Currency.exchange_to_f(1000, Currency.current_currency))}

      end

      context 'less than 500 not chinese' do
        let(:is_hieroglyph){false}
        let(:words_count){450}

        it {is_expected.to eq(Currency.exchange_to_f(1000 * 500, Currency.current_currency))}

      end

      context 'less than 1000 chinese' do

        let(:is_hieroglyph){true}
        let(:words_count){700}

        it {is_expected.to eq(Currency.exchange_to_f(1000 * 800, Currency.current_currency))}

      end

      context 'more than 800 chinese' do

        let(:is_hieroglyph){true}
        let(:words_count){1000}

        it {is_expected.to eq(Currency.exchange_to_f(1000 * 1000, Currency.current_currency))}

      end

      context 'more than 500 not chinese' do

        let(:is_hieroglyph){false}
        let(:words_count){600}

        it {is_expected.to eq(Currency.exchange_to_f(1000 * 600, Currency.current_currency))}

      end
    end

    before(:each) do
      order.stub(:base_lang_cost).and_return(1000)
      order.stub(:quantity_for_translate).and_return(900)
    end

    context 'currency' do
      it 'return language price with markup' do
        expect(order.lang_price(lang)).to eq(Currency.exchange_to_f(1000 * order.quantity_for_translate, Currency.current_currency))
      end
    end

  end

  describe '#cost' do
    let(:expected_price) {700 * order.quantity_for_translate}

    it 'return order cost' do
      expect(order.cost).to eq(Currency.exchange_to_f(expected_price, Currency.current_currency))
    end
  end

  describe '#price' do
    let(:expected_price) {1000 * order.quantity_for_translate}


    context 'without pass currency' do
      it 'return order price' do
        expect(order.price).to eq(Currency.exchange_to_f(expected_price, Currency.current_currency))
      end
    end

    context 'pass currency' do
      it 'return order price in RUB' do
        expect(order.price('RUB')).to eq(Currency.exchange_to_f(expected_price, 'RUB'))
      end
    end
  end

  describe '#real_translation_language' do
    let(:chinese){create :language, is_chinese: true}
    let(:not_chinese){create :language}
    subject{order.real_translation_language}
    context 'no language' do

      let(:order){create :order_written, translation_language: nil, original_language: nil }

      it 'expect nil' do
        expect(subject).to eq(nil)
      end
    end

    context 'translation not chinese' do

      let(:order){create :order_written, translation_language: not_chinese, original_language: chinese}

      it 'expect not chinese' do
        expect(subject).to eq(not_chinese)
      end

    end

    context 'translation not chinese other nil' do

      let(:order){create :order_written, translation_language: not_chinese, original_language: nil}

      it 'expect not chinese' do
        expect(subject).to eq(not_chinese)
      end

    end

    context 'original not chinese' do

      let(:order){create :order_written, translation_language: chinese, original_language: not_chinese}

      it 'expect not chinese' do
        expect(subject).to eq(not_chinese)
      end
    end

    context 'original not chinese other nil' do

      let(:order){create :order_written, translation_language: nil, original_language: not_chinese}

      it 'expect not chinese' do
        expect(subject).to eq(not_chinese)
      end
    end
  end

  describe '#cash flow' do

    let(:translator){create :profile_translator}
    let(:senior){create :profile_translator}
    let(:language){create :language, senior: senior}
    let(:chinese){create :language, is_hieroglyph: true}
    let(:client){create :profile_client}

    let(:invoice) {create :invoice, user: client.user }

    before(:each){
      Currency.create iso_code: 'USD'
      Currency.create iso_code: 'CNY'
      Currency.create iso_code: 'EUR'
      # Invoice.all.each do |invoice|
      #   invoice.update_attributes wechat: 's', phone: '23'
      # end
      # invoice.update_attributes wechat: 'a', phone: '22'
      order.stub(:price){1000}
      client.user.update balance: 10000
      order.invoices.last.stub(:cost){1000}
    }

    context 'on paid' do

      subject{order.invoices.last.paying; order.invoices.last.paid}

      let!(:order){create :order_written, state: :new, translation_type: 'translate', assignee: translator,
                         original_language: language, translation_language: chinese, owner: client, invoices: [invoice],
                         order_type: language.languages_group.written_prices.first.written_type}


      it('user balance'){expect{subject}.to change{client.user.balance}.by(-1000)}
      it('office balance'){expect{subject}.to change{Office.head.balance}.by(1000)}

    end

    # context 'order closed' do
    #
    #   subject{order.close}
    #
    #   context 'translate' do
    #
    #     let(:order){create :order_written, state: :sent_to_client, translation_type: 'translate', assignee: translator,
    #                        original_language: language, translation_language: chinese, owner: client}
    #
    #     it 'cash to translator' do
    #       expect{subject}.to change{translator.user.balance.to_f}.by (1000*0.95*0.7)
    #     end
    #
    #     it 'cash to translator' do
    #       expect{subject}.to change{senior.user.balance.to_f}.by (1000*0.95*0.03)
    #     end
    #
    #   end
    #
    #   context 'translate_and_correct' do
    #     let(:order){create :order_written, state: :sent_to_client, translation_type: 'translate_and_correct', assignee: translator,
    #                        original_language: language, translation_language: chinese, invoices: [invoice]}
    #
    #     it 'cash to translator' do
    #       expect{subject}.to change{translator.user.balance.to_f}.by (1000*0.95*0.7*0.7)
    #     end
    #
    #     it 'cash to translator' do
    #       expect{subject}.to change{senior.user.balance.to_f}.by (1000*0.95*0.03+ 1000*0.95*0.7*0.3)
    #     end
    #   end
    #
    # end
  end

  # describe '#cost' do
  #   let(:expected_cost) do
  #     (order.translation_languages.inject (0) {|sum, l| sum + l.written_cost(order.level)}) * order.words_number
  #   end
  #
  #   context 'pass level' do
  #     let(:level) {'law'}
  #     subject{order.cost nil, level}
  #     it {is_expected.to eq(expected_cost)}
  #     it {expect(subject.to_f).not_to eq(Float::INFINITY)}
  #
  #   end
  #
  #   context 'without pass arguments' do
  #     let(:level) {order.level}
  #     subject{order.cost}
  #     it {is_expected.to eq(expected_cost)}
  #     it {expect(subject.to_f).not_to eq(Float::INFINITY)}
  #   end
  # end
  #
  # describe '#price' do
  #   it 'returns cost with markup' do
  #     expect(order.price).to eq(Price.with_markup(order.cost))
  #   end
  # end

  describe '#available_for' do

    let(:lang1){create :language}
    let(:lang2){create :language}
    let(:lang3){create :language}
    let(:chinese){create :language, is_hieroglyph: true}

    let(:translator){create :profile_translator, services:
                  [build(:service, written_approves: true, written_translate_type: 'From chinese', language: lang1),
                   build(:service, written_approves: true, written_translate_type: 'From-to chinese', language: lang2)]}


    subject{Order::Written.available_for(translator)}

    let(:order1){create :order_written, original_language: chinese, translation_language: lang1}
    let(:order2){create :order_written, original_language: chinese, translation_language: lang2}
    let(:order3){create :order_written, original_language: lang2, translation_language: chinese}

    before(:each) do
      order1
      order2
      order3
      create :order_written, original_language: lang3, translation_language: chinese
      create :order_written, original_language: chinese, translation_language: lang3
    end

    it 'orders count' do
      expect(subject.count).to eq(3)
    end

    it 'includes orders' do
      expect(subject).to include(order1)
      expect(subject).to include(order2)
      expect(subject).to include(order3)
    end


  end

  describe '#paying_items' do

    subject{order.paying_items}

    context 'translate' do

      let(:order){create :order_written, translation_type: 'translate', quantity_for_translate: 1200}

      before(:each) do
        order.stub(:base_lang_cost).and_return 10
      end

      it ('only one') {expect(subject.count).to eq(1)}
      it ('cost') {expect(subject[0][:cost]).to eq(12000)}

    end

    context 'translate and correct' do

      let(:order){create :order_written, translation_type: 'translate_and_correct', quantity_for_translate: 1200}

      before(:each) do
        order.stub(:base_lang_cost).and_return 10
        Price.stub(:get_increase_percent).and_return 1.33
      end

      it ('two') {expect(subject.count).to eq(2)}
      it ('cost') {expect(subject[0][:cost]).to eq(12000)}
      it ('cost') {expect(subject[1][:cost]).to eq(3960)}

    end

    context 'surcharge for postage' do

      let(:order){create :order_written, translation_type: 'translate_and_correct', quantity_for_translate: 1200}

      before(:each) do
        order.stub(:base_lang_cost).and_return 10
        Price.stub(:get_increase_percent).and_return 1.33
        order.get_original.update_attributes(send_type: 'post', name: 'd', address: 's', index: '1')
      end

      it ('three') {expect(subject.count).to eq(3)}
      it ('cost') {expect(subject[0][:cost]).to eq(12000)}
      it ('cost') {expect(subject[1][:cost]).to eq(3960)}
      it ('cost') {expect(subject[2][:cost]).to eq(30)}

    end

  end

  describe '#days_for_work' do

    let(:order){create :order_written, attrs}

    subject{order.days_for_work}

    context 'document translations' do
      let(:number){8}

      let(:attrs) {{quantity_for_translate: number}}

      before(:each){Order::Written::WrittenType.any_instance.stub(:type_name).and_return('document')}

      it{is_expected.to eq(1)}

    end

    context 'translate for words' do

      let(:number){1500}

      before(:each){Order::Written::WrittenType.any_instance.stub(:type_name).and_return('text')}

      let(:number){8}
      let(:attrs) {{translation_type: 'translate', quantity_for_translate: number}}

      it{is_expected.to eq(1)}
    end

    context 'translate for chars' do

      let(:number){2400}

      let(:attrs) {{translation_type: 'translate', quantity_for_translate: number}}

      before(:each){Order::Written::WrittenType.any_instance.stub(:type_name).and_return('text'); Language.any_instance.stub(:is_hieroglyph).and_return(true)}

      it{is_expected.to eq(1)}

    end


    context 'translate ans correct for words' do

      let(:number){4500}

      let(:attrs) {{translation_type: 'translate_and_correct', quantity_for_translate: number}}

      before(:each){Order::Written::WrittenType.any_instance.stub(:type_name).and_return('text')}

      it{is_expected.to eq(4)}

    end

    context 'translate and correct for chars' do

      let(:number){7200}

      let(:attrs) {{translation_type: 'translate_and_correct', quantity_for_translate: number}}

      before(:each){Order::Written::WrittenType.any_instance.stub(:type_name).and_return('text'); Language.any_instance.stub(:is_hieroglyph).and_return(true)}

      it{is_expected.to eq(4)}

    end

  end

  # describe '#paid' do
  #   let(:lang) {create :language}
  #   let(:chinese_lang) {create :language, is_chinese: true}
  #   subject{order.paid}
  #
  # end

end