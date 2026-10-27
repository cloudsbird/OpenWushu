# Preview all emails at http://localhost:3000/rails/mailers/email_verification_mailer
class EmailVerificationMailerPreview < ActionMailer::Preview
  def verify
    EmailVerificationMailer.verify(PreviewUser.call(params))
  end
end
