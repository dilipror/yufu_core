class I18nJsExportWorker
  include Sidekiq::Worker

  def perform
    I18n::JS.export
  end
end
