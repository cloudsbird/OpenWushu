# Preview all emails at http://localhost:3000/rails/mailers/passwords_mailer
class PasswordsMailerPreview < ActionMailer::Preview
  def reset
    PasswordsMailer.reset(PreviewUser.call(params))
  end
end
