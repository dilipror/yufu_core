# desc "Explaining what the task does"
# task :yufu_core do
#   # Task goes here
# end

namespace :yufu_core do
  desc 'Set verbal level as Integer'
  task set_int_lvl: :environment do
    Order::Verbal.update_all level: 1
    Profile::Service.update_all level: 1
    Order::LanguageCriterion.update_all level: 1
  end

  desc 'Set next item for old translations'
  task repair_translations: :environment do
    Localization::Version.each do |v|
      v.translations.each &:save
    end
  end
end