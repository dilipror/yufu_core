module MailerHelper

  include ActionView::Helpers::UrlHelper
  include Devise::Controllers::UrlHelpers

  def client(user)
    "#{user.first_name} #{user.last_name}"
  end

  def dashboard_link
    dashboard_url
  end

  def order_details(order)
    "#{I18n.t('notifications.order_details.location')} - #{order.location.name}, #{I18n.t('notifications.order_details.language')} -  #{order.language.name}, #{I18n.t('notifications.order_details.greeted_at')} - #{order.meeting_in}, #{formatted_time order.greeted_at_hour, order.greeted_at_minute}"
  end

  def interpreter_name(order)
    "#{ order.primary_offer.try(:translator).try(:user).try(:last_name)} #{order.primary_offer.try(:translator).try(:user).try(:last_name)}"
  end

  def phone_number(order)
    "#{ order.primary_offer.try(:translator).try(:user).try(:phone)}"
  end

  def confirm(resource, token)
    confirmation_url(resource, confirmation_token: token, locale: Localization.get_current.name)
  end

  def password_url(resource, token)
    edit_password_url(resource, reset_password_token: token)
  end

  class MailPage
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Context
    include ActionView::Helpers::AssetUrlHelper

    attr_accessor :root_url
    attr_accessor :round_link_url

    def initialize( root_url )
      self.root_url = root_url.gsub(/\/$/, '')
    end

    def h1(text )
      content_tag :h1, text, style: "color: #c65aa2; font-size: 25px; font-family: 'Open Sans', sans-serif;"
    end


    def p(text)
      content_tag :p, text, style: "font-size: 17px; font-family: 'Open Sans', sans-serif;"
    end

    def inline_bold(text)
      content_tag :span, text, style: "font-weight: bold; font-family: 'Open Sans', sans-serif;"
    end

    def round_link(text, href, link_url)
      content_tag :span do
        html =  content_tag :i, nil, style: "height: 26px; width: 26px; display: inline-block; vertical-align: top; background: url(#{root_url}#{link_url}) no-repeat;"
        html += content_tag :a, text, href: href, style: "color: #ef269d; text-decoration: none; line-height: 26px; margin-left: 5px; font-size: 17px; font-family: 'Open Sans', sans-serif;"
      end
    end

  end

  def mail_layout(&block)

    page = MailPage.new(root_url)


    html = content_tag :table, style: "margin: auto;
                                   width: 700px;" do

      html = content_tag :tr, style: "margin: auto;
                                   width: 700px;
                                   height: 150px;
                                   background: url('#{root_url}#{image_url('header_bg.png')}')" do
        html = content_tag(:td,nil, style: "margin: auto;
                                      width: 700px;
                                      height: 14px;
                                      bottom: -10px;
                                      background: url(#{root_url}#{image_url('border_top.png')})")
        html += content_tag(:td) do
          html = content_tag(:a, nil, href: 'http://yufu.net', style: "background: url('#{root_url}#{image_url('logo_small.png')}') no-repeat;
                                                                        display: block;
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
      end
    end
    html = content_tag :table, style: "margin: auto;
                                   width: 700px;" do

      html += content_tag :tr, style: "margin: auto;
                                        width: 700px;
                                        padding-left: 30px;
                                        padding-bottom: 30px" do
        content_tag :td do
          block.call(page)
        end
      end
    end

    html = content_tag :table, style: "margin: auto;
                                   width: 700px;" do

      html += content_tag :tr, style: "position: relative;
                                     margin: auto;
                                     width: 700px;
                                     background-color: #924fab;
                                     height: 36px;"  do
        html = content_tag(:tr,nil, style: "margin: auto;
                                        width: 700px;
                                        height: 14px;
                                        top: -10px;
                                        background: url(#{root_url}#{image_url('border_top.png')})")
        html += content_tag(:tr, style: 'margin-left: 20px' ) do
          html = content_tag(:td) do
            html = content_tag(:span, I18n.t('mailer.yufu_phone'), style: "line-height: 35px; color: #ffffff; font-size: 14px; font-family: 'Open Sans', sans-serif;")
          end
          html += content_tag(:td) do
            html = content_tag(:a,'408.341.0600', href:'tel:408 341 0600 ', style: "text-decoration: none; line-height: 35px; color: #ffffff; font-size: 14px; font-family: 'Open Sans', sans-serif;")
          end
          html += content_tag(:td) do
            html = content_tag(:span, ' Email: ', style: "line-height: 35px; color: #ffffff; font-size: 14px; font-family: 'Open Sans', sans-serif;")
          end
          html += content_tag(:td) do
            html = content_tag(:a,'contacts@yufu.net', href: 'mailto: contacts@yufu.net', style: "text-decoration: none; line-height: 35px; color: #ffffff; font-size: 14px; font-family: 'Open Sans', sans-serif;")
          end
        end
      end
      html += content_tag(:tr, style: "width: 700px; height: 20px; margin: auto; padding-top: 10px") do
        html = content_tag(:td, style: "width: 50px") do
          html = content_tag(:a, I18n.t('mailer.terms'), href: "#",style: "text-decoration: none; padding: 0 5px 0 5px; color: #924fab; font-size: 12px; border-right: 1px #924fab solid")
        end
        html += content_tag(:td, style: "width: 50px") do
          html = content_tag(:a, I18n.t('mailer.privacy'), href: "#",style: "text-decoration: none; padding: 0 5px 0 5px;color: #924fab; font-size: 12px; border-right: 1px #924fab solid")
        end
        html += content_tag(:td, style: "width: 50px") do
          html = content_tag(:a, I18n.t('mailer.unsubscribe'), href: "#", style: "text-decoration: none; padding: 0 5px 0 5px;color: #924fab; font-size: 12px")
        end
        html += content_tag :td,"", style: "width: 700px"
        html += content_tag(:td, style: "width: 50px") do
          html = content_tag :span, I18n.t("mailer.connect_with_us"), style: "color: #924fab; font-size: 12px;"
        end
        html += content_tag(:td, style: "width: 50px") do
          html = content_tag :a, nil, href: "#", style: "height: 22px;
                                                    display: inline-block;
                                                    vertical-align: middle;
                                                    width: 22px;
                                                    background-position: 0 0px;
                                                    margin-right: 5px;
                                                    margin-left: 5px;
                                                    background: url(#{root_url}#{image_url('mail_icons.png')}) no-repeat;"
        end
        html += content_tag(:td, style: "width: 50px") do
          html = content_tag :a, nil, href: "#", style: "height: 22px;
                                                    vertical-align: middle;
                                                    width: 22px;
                                                    margin-right: 5px;
                                                    background: url(#{root_url}#{image_url('mail_icons.png')}) -25px 0  no-repeat;"
        end
        html += content_tag(:td, style: "width: 50px") do
          html = content_tag :a, nil, href: "#", style: "height: 22px;
                                                    vertical-align: middle;
                                                    width: 22px;
                                                    margin-right: 5px;
                                                    background: url(#{root_url}#{image_url('mail_icons.png')}) -51px 0  no-repeat;"
        end
      end
    end
  end

  def mail_header

    page = MailPage.new(root_url)


    html = content_tag :div, style: "margin: auto;
                                     width: 700px;
                                     height: 150px;
                                     position: relative;
                                     background: url('#{root_url}#{image_url('header_bg.png')}')" do
      html = content_tag(:a, nil, href: 'http://yufu.net', style: "background: url('#{root_url}#{image_url('logo_small.png')}') no-repeat;
                                                                    display: block;
                                                                    top: 20px;
                                                                    left: 40px;
                                                                    float: left;
                                                                    position: absolute;
                                                                    height: 83px;
                                                                    width: 131px;")
      html += content_tag(:p, raw(I18n.t(:slogan)), style: "font-size: 30px;
                                                  text-align: right;
                                                  margin-left: 250px;
                                                  font-family: 'Open Sans', sans-serif;
                                                  padding-top: 15px;
                                                  padding-right: 10px;
                                                  position: absolute;
                                                  line-height: 1;")


    end
    # html = content_tag :table, style: "margin: auto;
    #                                width: 700px;" do
    #
    #   html = content_tag :tr, style: "margin: auto;
    #                                width: 700px;
    #                                height: 150px;
    #                                position: relative
    #                                background: url('#{root_url}#{image_url('header_bg.png')}')" do
    #     html = content_tag(:td,nil, style: "margin: auto;
    #                                   width: 700px;
    #                                   height: 14px;
    #                                   bottom: -10px;
    #                                   position: absolute;
    #                                   background: url(#{root_url}#{image_url('border_top.png')})")
    #     html += content_tag(:td) do
    #       html = content_tag(:a, nil, href: 'http://yufu.net', style: "background: url('#{root_url}#{image_url('logo_small.png')}') no-repeat;
    #                                                                     display: block;
    #                                                                     top: 20px;
    #                                                                     left: 40px;
    #                                                                     float: left;
    #                                                                     height: 83px;
    #                                                                     width: 131px;")
    #       html += content_tag(:p, raw(I18n.t(:slogan)), style: "font-size: 30px;
    #                                                   text-align: right;
    #                                                   margin-left: 250px;
    #                                                   font-family: 'Open Sans', sans-serif;
    #                                                   padding-top: 15px;
    #                                                   padding-right: 10px;
    #                                                   line-height: 1;")
    #     end
    #   end
    # end



  end

end