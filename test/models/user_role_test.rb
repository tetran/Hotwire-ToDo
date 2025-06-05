require "test_helper"

class UserRoleTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    @user = User.create!(email: "test@example.com", password: "password123")
    @role = Role.create!(name: "test_role")
    @user_role = UserRole.new(user: @user, role: @role)
  end

  def teardown
    UserRole.delete_all
    RolePermission.delete_all
    Role.delete_all
    Permission.delete_all
    Comment.delete_all
    ProjectMember.delete_all
    SuggestedTask.delete_all
    SuggestionResponse.delete_all
    SuggestionRequest.delete_all
    Task.delete_all
    Project.delete_all
    User.delete_all
  end

  test "should be valid with valid attributes" do
    assert @user_role.valid?
  end

  test "should require user" do
    @user_role.user = nil
    assert_not @user_role.valid?
    assert_includes @user_role.errors[:user], "must exist"
  end

  test "should require role" do
    @user_role.role = nil
    assert_not @user_role.valid?
    assert_includes @user_role.errors[:role], "must exist"
  end

  test "should require unique combination of user and role" do
    UserRole.create!(user: @user, role: @role)
    duplicate_user_role = UserRole.new(user: @user, role: @role)

    assert_not duplicate_user_role.valid?
    assert_includes duplicate_user_role.errors[:user_id], "has already been taken"
  end

  test "should allow same user with different roles" do
    role2 = Role.create!(name: "another_role")
    UserRole.create!(user: @user, role: @role)
    user_role2 = UserRole.new(user: @user, role: role2)

    assert user_role2.valid?
  end

  test "should allow same role with different users" do
    user2 = User.create!(email: "test2@example.com", password: "password123")
    UserRole.create!(user: @user, role: @role)
    user_role2 = UserRole.new(user: user2, role: @role)

    assert user_role2.valid?
  end

  test "should belong to user" do
    user_role = UserRole.create!(user: @user, role: @role)
    assert_equal @user, user_role.user
  end

  test "should belong to role" do
    user_role = UserRole.create!(user: @user, role: @role)
    assert_equal @role, user_role.role
  end
end
