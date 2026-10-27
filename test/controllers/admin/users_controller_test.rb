require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "index searches and filters" do
    get admin_users_path(q: "budi")
    assert_select "tbody tr", 1
    assert_select "tbody td", /new@example.com/

    get admin_users_path(filter: "unverified")
    assert_select "tbody tr", 1

    get admin_users_path(filter: "admin")
    assert_select "tbody td a", "Sari"
  end

  test "update edits the profile and role" do
    user = users(:one)
    patch admin_user_path(user), params: { user: { display_name: "Ana Putri", role: "maintainer" } }
    assert_redirected_to admin_user_path(user)
    assert_equal [ "Ana Putri", "maintainer" ], user.reload.values_at(:display_name, :role)
  end

  test "changing the email needs a new verification" do
    user = users(:one)
    patch admin_user_path(user), params: { user: { email_address: "ana.new@example.com" } }
    assert_not user.reload.verified?
  end

  test "update shows errors" do
    patch admin_user_path(users(:one)), params: { user: { display_name: "" } }
    assert_response :unprocessable_entity
    assert_select ".field__error", /display name/
  end

  test "suspend signs the member out and blocks sign-in" do
    user = users(:one)
    session = user.sessions.create!
    post suspend_admin_user_path(user)
    assert user.reload.suspended?
    assert_not Session.exists?(session.id)

    sign_out
    post session_path, params: { email_address: user.email_address, password: "password" }
    assert_response :unprocessable_entity
    assert_select "[role=alert]", /suspended/

    sign_in_as users(:admin)
    post unsuspend_admin_user_path(user)
    assert_not user.reload.suspended?
  end

  test "a suspended member's existing session stops working" do
    member = users(:one)
    sign_in_as member
    member.update_column(:suspended_at, Time.current)
    get email_verification_path
    assert_redirected_to new_session_path
  end

  test "verify, sign out everywhere and password reset" do
    user = users(:unverified)
    user.sessions.create!
    post verify_admin_user_path(user)
    assert user.reload.verified?
    post sign_out_everywhere_admin_user_path(user)
    assert_empty user.sessions
    post password_reset_admin_user_path(user)
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ user ]
  end

  test "destroy" do
    assert_difference -> { User.count }, -1 do
      delete admin_user_path(users(:one))
    end
    assert_redirected_to admin_users_path
  end

  test "admins can't suspend, demote or delete themselves" do
    admin = users(:admin)
    post suspend_admin_user_path(admin)
    patch admin_user_path(admin), params: { user: { role: "member" } }
    delete admin_user_path(admin)
    admin.reload
    assert admin.admin?
    assert_not admin.suspended?
  end

  test "saving one's own profile without the role keeps admin" do
    admin = users(:admin)
    patch admin_user_path(admin), params: { user: { display_name: "Sari W" } }
    assert_redirected_to admin_user_path(admin)
    assert_equal "Sari W", admin.reload.display_name
    assert admin.admin?
  end
end
