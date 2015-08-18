module Price
  MARKUP = 1
  # Convert cost to price with 30% Markup
  def self.with_markup(cost)
    return BigDecimal::INFINITY if cost.eql? BigDecimal::INFINITY
    ((cost / MARKUP)*100).to_i.to_f/100
  end

  def self.without_markup(cost)
    0.7 * cost
  end

  # for exchange between CNY and other currencies
  def self.exchange_currency(value, to = nil)
    eu_central_bank = ExchangeBank.instance
    if to.nil?
      eu_central_bank.exchange(value.cents, 'CNY', Currency.current_currency)
    else
      eu_central_bank.exchange(value.cents, 'CNY', to)
    end
  rescue
    0
  end


  def self.get_increase_percent(language = nil, level = nil)
    if level.nil? or language.nil?
      return 0
    else
      lan_grp = language.languages_group
      wrt_prc = lan_grp.written_prices.find_by level: level
      return wrt_prc.increase_price
    end
  end

end