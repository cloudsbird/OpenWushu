class ApplicationController < ActionController::Base
  include Authentication
  # Many learners use older Android phones, so require only what the app uses: import maps and class fields.
  allow_browser versions: { chrome: 89, safari: 16.4, firefox: 108, opera: 75, ie: false }

  around_action :switch_locale
  helper_method :site_settings, :signed_in_user

  private

  # ?locale=en|id switches the translation and remembers it; otherwise use the cookie, then the browser.
  def switch_locale(&action)
    locale = params[:locale].presence_in(I18n.available_locales.map(&:to_s))
    cookies.permanent[:locale] = locale if locale
    locale ||= cookies[:locale].presence_in(I18n.available_locales.map(&:to_s))
    locale ||= request.headers["Accept-Language"].to_s.match?(/\A\s*(id|ms)\b/i) ? "id" : "en"
    I18n.with_locale(locale, &action)
  end

  # The signed-in user, also on pages open to visitors: there the session is only loaded on demand,
  # so Current.user alone would be nil
  def signed_in_user
    Current.user if authenticated?
  end

  # Read once per request, never cached, so changes in Admin > Settings show at once
  def site_settings
    @site_settings ||= Setting.current
  end

  # Sign-in and sign-up pages make no sense once signed in
  def redirect_if_authenticated
    redirect_to root_path if authenticated?
  end
end
