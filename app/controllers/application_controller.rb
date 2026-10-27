class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  around_action :switch_locale

  private

  # ?locale=en|id switches the translation and remembers it; otherwise use the cookie, then the browser.
  def switch_locale(&action)
    locale = params[:locale].presence_in(I18n.available_locales.map(&:to_s))
    cookies.permanent[:locale] = locale if locale
    locale ||= cookies[:locale].presence_in(I18n.available_locales.map(&:to_s))
    locale ||= request.headers["Accept-Language"].to_s.match?(/\A\s*(id|ms)\b/i) ? "id" : "en"
    I18n.with_locale(locale, &action)
  end
end
