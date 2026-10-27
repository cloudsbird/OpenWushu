require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset" do
    mail = PasswordsMailer.reset(users(:one))
    assert_equal "Reset your OpenWushu password", mail.subject
    assert_match "15 minutes", mail.text_part.body.to_s
    assert_match "/passwords/", mail.html_part.body.to_s
  end
end
