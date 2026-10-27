require "test_helper"

class Admin::AccessTest < ActionDispatch::IntegrationTest
  PATHS = %w[/admin/users /admin/routines /admin/settings].freeze

  test "visitors are asked to sign in" do
    PATHS.each do |path|
      get path
      assert_redirected_to new_session_path, path
    end
  end

  test "members get a 404" do
    sign_in_as users(:one)
    PATHS.each do |path|
      get path
      assert_response :not_found, path
    end
    post suspend_admin_user_path(users(:unverified))
    assert_response :not_found
    assert_not users(:unverified).reload.suspended?
  end

  test "admins see the panel and the Admin link" do
    sign_in_as users(:admin)
    PATHS.each do |path|
      get path
      assert_response :success, path
    end
    assert_select ".site-nav a[href=?]", admin_root_path
  end

  test "members don't see the Admin link" do
    sign_in_as users(:one)
    get root_path
    assert_select ".site-nav a[href=?]", admin_root_path, count: 0
  end

  # Through the real sign-in form, so nothing is preloaded in Current
  test "the Admin link shows on public pages after signing in" do
    post session_path, params: { email_address: users(:admin).email_address, password: "password" }
    get root_path
    assert_select ".site-nav a[href=?]", admin_root_path
  end
end
