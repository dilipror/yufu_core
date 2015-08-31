FactoryGirl.define do
  factory :tax_uk_vat, :class => 'Tax' do
    name 'UK VAT'
    countries {[create(:eu_country)]}
    # company {create(:gbp_company)}
    payment_gateways {[create(:payment_bank), create(:payment_local_balance)]}
    original_is_needed false
    tax 20
  end

  factory :tax_busness, :class => 'Tax' do
    name 'Busness tax'
    countries {[create(:hongkong_country)]}
    # company {create(:gbp_company)}
    payment_gateways {[create(:payment_bank), create(:payment_local_balance)]}
    original_is_needed false
    tax 10
  end

  factory :tax_add_surch, :class => 'Tax' do
    name 'Additional tax surcharge'
    countries {[create(:country)]}
    # company {create(:cny_company)}
    payment_gateways {[create(:payment_bank)]}
    original_is_needed false
    tax 10
  end

  factory :tax_add_bus_tax, :class => 'Tax' do
    name 'Additional business tax'
    countries {[create(:country)]}
    # company {create(:cny_company)}
    payment_gateways {[create(:payment_bank), create(:payment_local_balance)]}
    original_is_needed true
    tax 3
  end

end
