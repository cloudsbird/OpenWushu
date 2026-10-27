require "test_helper"

class AdminTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("admin:grant")
    Rake::Task["admin:grant"].reenable
  end

  test "grant makes an existing account an admin and verifies it" do
    assert_output(/now an admin/) { Rake::Task["admin:grant"].invoke("NEW@example.com") }
    user = users(:unverified).reload
    assert user.admin?
    assert user.verified?
  end
end
