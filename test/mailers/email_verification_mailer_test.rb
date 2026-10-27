require "test_helper"

class EmailVerificationMailerTest < ActionMailer::TestCase
  test "verify is sent in the member's translation with a working link" do
    user = users(:unverified)
    mail = EmailVerificationMailer.verify(user)

    assert_equal [ user.email_address ], mail.to
    assert_equal "Verifikasi email Anda untuk OpenWushu", mail.subject
    assert_match "Halo Budi", mail.text_part.body.to_s
    token = mail.html_part.body.to_s[%r{/email_verification/([^"]+)"}, 1]
    assert_equal user, User.find_by_token_for(:email_verification, CGI.unescapeHTML(token))
  end
end
