require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email, name and club" do
    user = User.new(email_address: " Ana@Example.COM ", display_name: "  Ana   S ", club: "  ")
    assert_equal "ana@example.com", user.email_address
    assert_equal "Ana S", user.display_name
    assert_nil user.club
  end

  test "accepting the guidelines records when" do
    user = User.new(accept_guidelines: "1")
    assert_in_delta Time.current, user.guidelines_accepted_at, 1
    user.accept_guidelines = "0"
    assert_nil user.guidelines_accepted_at
  end

  test "verify! sets verified_at once" do
    user = users(:unverified)
    user.verify!
    first = user.verified_at
    travel 1.minute do
      user.verify!
    end
    assert_equal first, user.reload.verified_at
  end

  test "rejects unknown translations" do
    user = users(:one)
    user.locale = "fr"
    assert_not user.valid?
  end

  test "last_admin? counts only other active admins" do
    admin = users(:admin)
    assert admin.last_admin?
    other = User.create!(display_name: "Dewi", email_address: "dewi@example.com", password: "long enough", accept_guidelines: "1", role: "admin")
    assert_not admin.last_admin?
    other.update!(suspended_at: Time.current)
    assert admin.last_admin?
    assert_not users(:one).last_admin?
  end

  test "suspend! ends sessions" do
    user = users(:one)
    user.sessions.create!
    user.suspend!
    assert user.suspended?
    assert_empty user.sessions
  end

  test "changing the email clears verification" do
    user = users(:one)
    user.update!(display_name: "Ana B")
    assert user.verified?
    user.update!(email_address: "ana.b@example.com")
    assert_not user.verified?
  end
end
