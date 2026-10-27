class AdminMailer < ApplicationMailer
  # From Admin > Settings, to check the SMTP details
  def test_email(user)
    @user = user
    mail_to user, ".subject"
  end
end
