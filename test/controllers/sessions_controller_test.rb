require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "new" do
    get new_session_path
    assert_response :success
    assert_select "h1", /登录/
  end

  test "create with valid credentials uses the account's translation" do
    post session_path, params: { email_address: users(:unverified).email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
    assert_equal "id", cookies[:locale]
  end

  test "create returns to the page that asked for sign-in" do
    get email_verification_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to email_verification_url
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_response :unprocessable_entity
    assert_select "[role=alert]", /don’t match/
    assert_nil cookies[:session_id]
  end

  test "signed-in members skip the sign-in page" do
    sign_in_as @user
    get new_session_path
    assert_redirected_to root_path
  end

  test "destroy" do
    sign_in_as @user

    delete session_path

    assert_redirected_to root_path
    assert_empty cookies[:session_id]
  end
end
