class I18nJsExportWorker < ActiveJob::Base
  queue_as :default

  def perform
    I18n::JS.export
  end
end
