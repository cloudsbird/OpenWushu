require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:unverified) }

  test "show needs a signed-in member" do
    get email_verification_path
    assert_redirected_to new_session_path
  end

  test "show sends verified members home" do
    sign_in_as users(:one)
    get email_verification_path
    assert_redirected_to root_path
  end

  test "resend" do
    sign_in_as @user
    post email_verification_path
    assert_enqueued_email_with EmailVerificationMailer, :verify, args: [ @user ]
    assert_redirected_to email_verification_path
  end

  test "the link verifies without signing in" do
    get verify_email_path(@user.generate_token_for(:email_verification))
    assert @user.reload.verified?
    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "the link sends a signed-in member home" do
    sign_in_as @user
    get verify_email_path(@user.generate_token_for(:email_verification))
    assert_redirected_to root_path
    follow_redirect!
    assert_select "[role=status]", /terverifikasi|verified/
  end

  test "an expired link is rejected" do
    token = @user.generate_token_for(:email_verification)
    travel 25.hours do
      get verify_email_path(token)
    end
    assert_not @user.reload.verified?
    assert_redirected_to new_session_path
  end

  test "a link for an old address is rejected" do
    token = @user.generate_token_for(:email_verification)
    @user.update!(email_address: "changed@example.com")
    get verify_email_path(token)
    assert_not @user.reload.verified?
  end
end
