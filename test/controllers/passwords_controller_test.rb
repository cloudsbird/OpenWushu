require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:unverified) }

  test "new" do
    get new_password_path
    assert_response :success
  end

  test "create" do
    post passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_select "[role=status]", /reset link is on its way/
  end

  test "create for an unknown user redirects but sends no mail" do
    post passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path

    follow_redirect!
    assert_select "[role=status]", /reset link is on its way/
  end

  test "edit" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")
    assert_redirected_to new_password_path

    follow_redirect!
    assert_select "[role=alert]", /invalid or has expired/
  end

  test "update changes the password, signs out other sessions and verifies the email" do
    @user.sessions.create!
    assert_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: { password: "new password", password_confirmation: "new password" }
      assert_redirected_to new_session_path
    end
    assert_empty @user.sessions
    assert @user.verified?

    follow_redirect!
    assert_select "[role=status]", /password has been changed/
  end

  test "update with non matching passwords" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "new password", password_confirmation: "different" }
      assert_response :unprocessable_entity
    end
    assert_select ".field__error", /don’t match/
  end

  test "update with a short password" do
    put password_path(@user.password_reset_token), params: { password: "short", password_confirmation: "short" }
    assert_response :unprocessable_entity
    assert_select ".field__error", /at least 8/
  end
end
