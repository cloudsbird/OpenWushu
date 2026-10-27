require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  def valid_params(**overrides)
    { user: { display_name: "Citra", email_address: " Citra@Example.com ", password: "long enough", locale: "id", club: "", accept_guidelines: "1" }.merge(overrides) }
  end

  test "new preselects the current translation" do
    get new_registration_path(locale: "id")
    assert_response :success
    assert_select "#user_locale_id[checked]"
  end

  test "create signs in, sends the verification email and shows the check-your-email page" do
    assert_difference -> { User.count } do
      post registration_path, params: valid_params
    end
    user = User.find_by!(email_address: "citra@example.com")
    assert_not user.verified?
    assert user.guidelines_accepted_at
    assert_nil user.club
    assert_equal "id", cookies[:locale]
    assert_enqueued_email_with EmailVerificationMailer, :verify, args: [ user ]
    assert_redirected_to email_verification_path

    follow_redirect!
    assert_select "strong", "citra@example.com"
  end

  test "create requires the community guidelines" do
    assert_no_difference -> { User.count } do
      post registration_path, params: valid_params(accept_guidelines: "0")
    end
    assert_response :unprocessable_entity
    assert_select ".field__error", /community guidelines/
  end

  test "create shows field errors" do
    post registration_path, params: valid_params(display_name: " ", email_address: users(:one).email_address, password: "short")
    assert_response :unprocessable_entity
    assert_select "#user_display_name_error", /display name/
    assert_select "#user_email_address_error", /already uses this email/
    assert_select "#user_password-error", /at least 8/
  end

  test "errors follow the page translation" do
    post registration_path(locale: "id"), params: valid_params(display_name: "")
    assert_select "#user_display_name_error", /Masukkan nama tampilan/
  end
end
