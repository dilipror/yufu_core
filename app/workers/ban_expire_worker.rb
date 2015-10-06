class BanExpireWorker
  include Sidekiq::Worker

  def perform(translator_id)
    translator = Profile::Translator.find translator_id
    translator.update is_banned: false
  end

end