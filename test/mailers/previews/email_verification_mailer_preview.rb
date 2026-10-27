# Preview all emails at http://localhost:3000/rails/mailers/email_verification_mailer
class EmailVerificationMailerPreview < ActionMailer::Preview
  def verify
    EmailVerificationMailer.verify(User.take)
  end
end
