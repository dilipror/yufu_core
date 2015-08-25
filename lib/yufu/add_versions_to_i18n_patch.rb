module I18n
  class Config
    def locale_version
      @locale_version ||= nil
    end

    # Sets the current locale pseudo-globally, i.e. in the Thread.current hash.
    def locale_version=(version_id)
      @locale_version = Localization::Version.find version_id
    end
  end
end