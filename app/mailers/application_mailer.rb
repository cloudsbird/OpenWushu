class ApplicationMailer < ActionMailer::Base
  default from: -> { Setting.current.mail_from || ENV.fetch("MAIL_FROM", "OpenWushu <notifications@example.com>") }
  layout "mailer"
  helper :revisions

  after_action :use_saved_smtp_settings

  private

  # Jobs run without the request's locale, so send each email in the recipient's chosen translation
  def mail_to(user, subject_key, **)
    I18n.with_locale(user.locale) do
      mail(to: user.email_address, subject: t(subject_key), **)
    end
  end

  # SMTP details saved in the admin panel win over credentials. Only when sending by SMTP,
  # so development keeps writing emails to tmp/mails.
  def use_saved_smtp_settings
    setting = Setting.current
    return unless message.delivery_method.is_a?(Mail::SMTP) && setting.smtp_configured?

    message.delivery_method.settings = message.delivery_method.settings.merge(setting.smtp_options)
  end
end
