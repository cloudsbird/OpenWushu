class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "OpenWushu <notifications@example.com>")
  layout "mailer"

  private

  # Jobs run without the request's locale, so send each email in the recipient's chosen translation
  def mail_to(user, subject_key, **)
    I18n.with_locale(user.locale) do
      mail(to: user.email_address, subject: t(subject_key), **)
    end
  end
end
