module Profile
  class ServiceFilter
    include Filterable

    def self.search(options = {})
      ServiceFilter.filter_language(3).filter_level(4).filter_email(33)
      # result = erviceFilter.all
      # result = result.merge(self.filter_language(options[:language_id]) if options[:language_id].present?)
      # result.send("filter_#{option[1]}")
      # result
    end

    def self.filter_language(language_id)
      Profile::Service.where language_id: language_id
    end

    def self.filter_level(level)
      Profile::Service.where level: level
    end

    def self.filter_email(email)
      user_ids = User.where(email: /.*#{email}.*/).distinct :id
      translator_ids = Profile::Translator.where(:user_id.in => user_ids).distinct :id
      Profile::Service.where :translator_id.in => translator_ids
    end
  end
end

# def self.email_qu(email)
#   translator_ids = Profile::Translator.where(email: email).distinct :id
#   where :translator_id.in => translator_ids
# end