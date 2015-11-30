module YufuHelper
  def root_with_locale
    host = Rails.application.config.try(:front_app_host) || Rails.application.config.try(:host)
    "#{host}/#{I18n.locale}"
  end

  def root_url
    root_with_locale
  end

  def change_password_url
    "#{root_with_locale}/office"
  end

  def login_url
    "#{root_with_locale}/login"
  end

  def new_verbal_order_url
    "#{root_with_locale}/verbals/new"
  end

  def balance_url
    "#{root_with_locale}/office/agent/billing/payments"
  end

  def dashboard_url
    "#{root_with_locale}/office"
  end

  def ts(key, options = {})
    ActionController::Base.helpers.content_tag(:span, {id: "#{key}", 'data-mercury' => 'simple'}) do
      (t key, options).html_safe
    end
  end

  def mail_with_params(key, params)
    # res = I18n.t(key)
    #
    # params.each_with_index do |param, i|
    #   res.gsub! "#param_#{i+1}", param
    # end
    #
    # raw res
  end

  def supported_locales
    Localization.all.map {|l| l.name.to_sym}
  end

  def locale_col_class(index)
    return 'clearfix' if index == 0
    Localization.enabled.count == index + 1 ? 'last' : ''
  end

  class MailPage
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Context
    include ActionView::Helpers::AssetUrlHelper

    attr_accessor :root_url
    attr_accessor :round_link_url

    def initialize( root_url )
      @root_url = root_url
    end

    def h1(text )
      content_tag :h1, text, style: "color: #c65aa2; font-size: 25px; font-family: 'Open Sans', sans-serif;"
    end

    def p(text)
      content_tag :p, text, style: "font-size: 17px; font-family: 'Open Sans', sans-serif;"
    end

    def round_link(text, href, link_url)
      content_tag :span do
        html =  content_tag :i, nil, style: "height: 26px; width: 26px; display: inline-block; vertical-align: top; background: url(#{link_url}) no-repeat;"
        html += content_tag :a, text, href: href, style: "color: #ef269d; text-decoration: none; line-height: 26px; margin-left: 5px; font-size: 17px; font-family: 'Open Sans', sans-serif;"
      end
    end

  end

  def mail_layout(&block)

    page = MailPage.new(root_url)

    html = content_tag :header, style: "position: relative;
                                 margin: auto;
                                 width: 700px;
                                 height: 150px;
                                 background: url('#{image_url('header_bg.png')}')" do
      html = content_tag(:div,nil, style: "margin: auto;
                                    width: 700px;
                                    height: 14px;
                                    position: absolute;
                                    bottom: -10px;
                                    background: url(#{image_url('border_top.png')})")
      html += content_tag(:a, nil, href: 'http://yufu.net', style: "background: url('#{image_url('logo_small.png')}') no-repeat;
                                                                    display: block;
                                                                    position: absolute;
                                                                    top: 20px;
                                                                    left: 40px;
                                                                    height: 83px;
                                                                    width: 131px;")
      html += content_tag(:p, raw(I18n.t(:slogan)), style: "font-size: 30px;
                                                  text-align: right;
                                                  margin-left: 250px;
                                                  font-family: 'Open Sans', sans-serif;
                                                  padding-top: 30px;
                                                  padding-right: 10px;
                                                  line-height: 1;")
    end

    html += content_tag :div, style: "margin: auto;
                                      width: 700px;
                                      padding-left: 30px;
                                      padding-bottom: 30px" do
      block.call(page)
    end

    html += content_tag :footer, style: "position: relative;
                                 margin: auto;
                                 width: 700px;
                                 background-color: #924fab;
                                 height: 36px;"  do
      html = content_tag(:div,nil, style: "margin: auto;
                                    width: 700px;
                                    height: 14px;
                                    position: absolute;
                                    top: -10px;
                                    background: url(#{image_url('border_top.png')})")
      html += content_tag(:div, style: 'margin-left: 20px' ) do
        html = content_tag(:span, I18n.t('mailer.yufu_phone'), style: "line-height: 35px; color: #ffffff; font-size: 14px; font-family: 'Open Sans', sans-serif;")
        html += content_tag(:a,'408.341.0600', href:'tel:408 341 0600 ', style: "text-decoration: none; line-height: 35px; color: #ffffff; font-size: 14px; font-family: 'Open Sans', sans-serif;")
        html += content_tag(:span, ' Email: ', style: "line-height: 35px; color: #ffffff; font-size: 14px; font-family: 'Open Sans', sans-serif;")
        html += content_tag(:a,'contacts@yufu.net', href: 'mailto: contacts@yufu.net', style: "text-decoration: none; line-height: 35px; color: #ffffff; font-size: 14px; font-family: 'Open Sans', sans-serif;")
      end
    end
    html += content_tag(:div, style: "width: 700px; height: 20px; margin: auto; padding-top: 10px") do
      html = content_tag(:div, style: "float: left") do
        html = content_tag(:a, I18n.t('mailer.terms'), href: "#",style: "text-decoration: none; padding: 0 5px 0 5px; color: #924fab; font-size: 12px; border-right: 1px #924fab solid")
        html += content_tag(:a, I18n.t('mailer.privacy'), href: "#",style: "text-decoration: none; padding: 0 5px 0 5px;color: #924fab; font-size: 12px; border-right: 1px #924fab solid")
        html += content_tag(:a, I18n.t('mailer.unsubscribe'), href: "#", style: "text-decoration: none; padding: 0 5px 0 5px;color: #924fab; font-size: 12px")
      end
      html += content_tag(:div, style: "float: right") do
        html = content_tag :span, I18n.t("mailer.connect_with_us"), style: "color: #924fab; font-size: 12px;"
        html += content_tag :a, nil, href: "#", style: "height: 22px;
                                                  display: inline-block;
                                                  vertical-align: middle;
                                                  width: 22px;
                                                  background-position: 0 0px;
                                                  margin-right: 5px;
                                                  margin-left: 5px;
                                                  background: url(#{image_url('mail_icons.png')}) no-repeat;"
        html += content_tag :a, nil, href: "#", style: "height: 22px;
                                                  display: inline-block;
                                                  vertical-align: middle;
                                                  width: 22px;
                                                  margin-right: 5px;
                                                  background: url(#{image_url('mail_icons.png')}) -25px 0  no-repeat;"

        html += content_tag :a, nil, href: "#", style: "height: 22px;
                                                  display: inline-block;
                                                  vertical-align: middle;
                                                  width: 22px;
                                                  margin-right: 5px;
                                                  background: url(#{image_url('mail_icons.png')}) -51px 0  no-repeat;"
      end
    end

  end

end
