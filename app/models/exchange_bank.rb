class ExchangeBank < EuCentralBank
  include Singleton
  @@updated = 0

  def updated
    @@updated
  end

  def self.update_rates
    instance.update_rates
  end

  def update_rates
    @@updated += 1
    super
  end
end