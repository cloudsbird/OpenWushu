require "test_helper"

class Admin::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "notice, footer and site name show on every page in the visitor's translation" do
    patch admin_settings_path, params: { setting: { notice_en: "Maintenance <b>Sunday</b>", notice_id: "Pemeliharaan Minggu", footer_en: "Our footer", site_name: "WushuRef", contact_email: "hi@example.org" } }
    assert_redirected_to admin_settings_path

    sign_out
    get root_path
    assert_select ".site-notice", "Maintenance <b>Sunday</b>"
    assert_select ".site-notice b", 0
    assert_select ".site-footer", /Our footer/
    assert_select ".site-footer a[href=?]", "mailto:hi@example.org"
    assert_select ".brand__name", "WushuRef"

    get root_path(locale: "id")
    assert_select ".site-notice", "Pemeliharaan Minggu"
    assert_select ".site-footer", /hanya untuk tujuan edukasi/
  end

  test "closing sign-ups hides the button and blocks new accounts" do
    patch admin_settings_path, params: { setting: { signups_open: "0" } }
    sign_out

    get root_path
    assert_select ".account a[href=?]", new_registration_path, count: 0
    get new_registration_path
    assert_response :forbidden
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { display_name: "X", email_address: "x@example.com", password: "long enough", locale: "en", accept_guidelines: "1" } }
    end
  end

  test "the SMTP password is stored encrypted, never shown, and kept when left empty" do
    patch admin_settings_path, params: { setting: { smtp_address: "smtp.example.org", smtp_port: "587", smtp_username: "mailer", smtp_password: "s3cret-pass" } }
    raw = ActiveRecord::Base.connection.select_value("SELECT smtp_password FROM settings")
    assert_not_includes raw, "s3cret-pass"
    assert_equal "s3cret-pass", Setting.current.smtp_password

    get admin_settings_path
    assert_not_includes response.body, "s3cret-pass"

    patch admin_settings_path, params: { setting: { smtp_username: "mailer2", smtp_password: "" } }
    assert_equal "s3cret-pass", Setting.current.reload.smtp_password

    delete smtp_password_admin_settings_path
    assert_nil Setting.current.reload.smtp_password
  end

  test "invalid settings show errors" do
    patch admin_settings_path, params: { setting: { site_name: "", source_url: "javascript:alert(1)", smtp_address: "smtp.example.org", smtp_port: "" } }
    assert_response :unprocessable_entity
    assert_select ".field__error", minimum: 3
  end

  test "test email is sent now and failures are shown" do
    assert_emails 1 do
      post test_email_admin_settings_path
    end
    assert_redirected_to admin_settings_path(anchor: "email")

    # Simulate the SMTP server refusing the login
    AdminMailer.define_singleton_method(:test_email) { |*| raise Net::SMTPAuthenticationError.new(nil, message: "535 bad credentials") }
    begin
      post test_email_admin_settings_path
    ensure
      AdminMailer.singleton_class.remove_method(:test_email)
    end
    follow_redirect!
    assert_select "[role=alert]", /could not be sent/
  end

  test "mailers use the saved sender" do
    Setting.current.update!(mail_from: "Wushu <noreply@example.org>")
    mail = PasswordsMailer.reset(users(:one))
    assert_equal [ "noreply@example.org" ], mail.from
  end
end
