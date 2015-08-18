class Currency
  include Mongoid::Document
  extend Enumerize

  field :name 
  field :iso_code
  field :symbol

  enumerize :iso_code, in: ['AED','AFN','ALL','AMD','ANG','AOA','ARS','AUD','AWG','AZN','BAM','BBD','BDT','BGN','BHD',
                            'BIF','BMD','BND','BOB','BRL','BSD','BTN','BWP','BYR','BZD','CAD','CDF','CHF','CLP','CNY',
                            'COP','CRC','CUC','CUP','CVE','CZK','DJF','DKK','DOP','DZD','EGP','ERN','ETB','EUR','FJD',
                            'FKP','GBP','GEL','GGP','GHS','GIP','GMD','GNF','GTQ','GYD','HKD','HNL','HRK','HTG','HUF',
                            'IDR','ILS','IMP','INR','IQD','IRR','ISK','JEP','JMD','JOD','JPY','KES','KGS','KHR','KMF',
                            'KPW','KRW','KWD','KYD','KZT','LAK','LBP','LKR','LRD','LSL','LYD','MAD','MDL','MGA','MKD',
                            'MMK','MNT','MOP','MRO','MUR','MVR','MWK','MXN','MYR','MZN','NAD','NGN','NIO','NOK','NPR',
                            'NZD','OMR','PAB','PEN','PGK','PHP','PKR','PLN','PYG','QAR','RON','RSD','RUB','RWF','SAR',
                            'SBD','SCR','SDG','SEK','SGD','SHP','SLL','SOS','SPL','SRD','STD','SVC','SYP','SZL','THB',
                            'TJS','TMT','TND','TOP','TRY','TTD','TVD','TWD','TZS','UAH','UGX','USD','UYU','UZS','VEF',
                            'VND','VUV','WST','XAF','XCD','XDR','XOF','XPF','YER','ZAR','ZMW','ZWD']

  def self.current_currency
    Thread.current[:current_currency] || 'CNY'
  end

  def self.current_currency=(value)
    Thread.current[:current_currency] = value
  end

  def self.name_from_iso_code(iso_code)
    find_by iso_code: iso_code
  end

  def self.exchange(value, currency = nil)
    value ||= 0
    return BigDecimal::INFINITY if  value == BigDecimal::INFINITY
    eu_central_bank = ExchangeBank.instance
    currency = currency || Currency.current_currency
    eu_central_bank.exchange(value * 100, 'CNY', currency)
  rescue
    999999
  end

  def self.exchange_to_f(value, currency = nil)
    self.exchange(value, currency).to_f
  end

  def self.get_symbol(iso_code = nil)
    if iso_code.nil?
      cur = Currency.current_currency
    else
      cur = iso_code
    end
    temp = Currency.name_from_iso_code(cur)
    if temp.symbol.present?
      temp.symbol
    else
      temp.iso_code
    end
  end

end
