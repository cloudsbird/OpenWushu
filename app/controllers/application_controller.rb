class ApplicationController < ActionController::Base
  include Authentication
  # Many learners use older Android phones, so require only what the app uses: import maps and class fields.
  allow_browser versions: { chrome: 89, safari: 16.4, firefox: 108, opera: 75, ie: false }

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

  # Sign-in and sign-up pages make no sense once signed in
  def redirect_if_authenticated
    redirect_to root_path if authenticated?
  end
end
