class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail_to user, ".subject"
  end
end
