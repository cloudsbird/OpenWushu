class Admin::SettingsController < Admin::BaseController
  before_action :set_setting

  def show
  end

  def update
    if @setting.update(setting_params)
      redirect_to admin_settings_path, notice: t("admin.settings.saved")
    else
      render :show, status: :unprocessable_entity
    end
  end

  # Sends right away (not in the background) so the result, or the server's error, shows on the page
  def test_email
    AdminMailer.test_email(Current.user).deliver_now
    redirect_to admin_settings_path(anchor: "email"), notice: t("admin.settings.test_sent", email: Current.user.email_address)
  rescue StandardError => e
    redirect_to admin_settings_path(anchor: "email"), alert: t("admin.settings.test_failed", error: e.message.truncate(200))
  end

  def destroy_smtp_password
    @setting.clear_smtp_password!
    redirect_to admin_settings_path(anchor: "email"), notice: t("admin.settings.password_cleared"), status: :see_other
  end

  private

  def set_setting
    @setting = Setting.current
  end

  def setting_params
    params.expect(setting: %i[signups_open verification_required notice_en notice_id site_name contact_email
                              footer_en footer_id source_url mail_from smtp_address smtp_port smtp_username smtp_password])
  end
end
