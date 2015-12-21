module DoWithLocale
  def do_with_locale(locale)
    old_locale = I18n.locale
    I18n.locale = locale

    yield

    I18n.locale = old_locale
  end
end