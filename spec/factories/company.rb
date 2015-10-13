FactoryGirl.define do
  factory :gbp_company, class: 'Company' do
    name 'M&N Finance'
    # currency Currency.find_by(iso_code: 'GBP')
    support_copy_invoice false
    association :currency
  end

  factory :cny_company, class: 'Company' do
    name 'YUFU.NET'
    # currency Currency.find_by(iso_code: 'CNY')
    support_copy_invoice true
    association :currency
  end

end
