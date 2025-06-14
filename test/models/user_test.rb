require "test_helper"

class UserTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    @user = User.create!(email: "test@example.com", password: "password123")
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

  test "should have many roles through user_roles" do
    role = Role.create!(name: "test_role")
    @user.roles << role
    assert_includes @user.roles, role
  end

  test "admin? should return true when user has admin role" do
    admin_role = Role.find_by(name: "admin", system_role: true)
    @user.roles << admin_role
    assert @user.admin?
  end

  test "admin? should return false when user does not have admin role" do
    regular_role = Role.find_by(name: "regular", system_role: false)
    @user.roles << regular_role
    assert_not @user.admin?
  end

  test "has_permission? should return true when user has specific permission" do
    role = Role.create!(name: "test_role")
    permission = Permission.find_by(resource_type: "User", action: "read")
    role.permissions << permission
    @user.roles << role

    assert @user.has_permission?("User", "read")
  end

  test "has_permission? should return false when user does not have specific permission" do
    role = Role.create!(name: "test_role")
    @user.roles << role

    assert_not @user.has_permission?("User", "read")
  end

  test "can_read? should return true when user has read permission" do
    role = Role.create!(name: "test_role")
    permission = Permission.find_by(resource_type: "User", action: "read")
    role.permissions << permission
    @user.roles << role

    assert @user.can_read?("User")
  end

  test "can_read? should return true when user has manage permission" do
    role = Role.create!(name: "test_role")
    permission = Permission.find_by(resource_type: "User", action: "manage")
    role.permissions << permission
    @user.roles << role

    assert @user.can_read?("User")
  end

  test "can_read? should return false when user has no read or manage permission" do
    role = Role.create!(name: "test_role")
    permission = Permission.find_by(resource_type: "User", action: "write")
    role.permissions << permission
    @user.roles << role

    assert_not @user.can_read?("User")
  end

  test "can_write? should return true when user has write permission" do
    role = Role.create!(name: "test_role")
    permission = Permission.find_by(resource_type: "User", action: "write")
    role.permissions << permission
    @user.roles << role

    assert @user.can_write?("User")
  end

  test "can_write? should return true when user has manage permission" do
    role = Role.create!(name: "test_role")
    permission = Permission.find_by(resource_type: "User", action: "manage")
    role.permissions << permission
    @user.roles << role

    assert @user.can_write?("User")
  end

  test "can_delete? should return true when user has delete permission" do
    role = Role.create!(name: "test_role")
    permission = Permission.find_by(resource_type: "User", action: "delete")
    role.permissions << permission
    @user.roles << role

    assert @user.can_delete?("User")
  end

  test "can_delete? should return true when user has manage permission" do
    role = Role.create!(name: "test_role")
    permission = Permission.find_by(resource_type: "User", action: "manage")
    role.permissions << permission
    @user.roles << role

    assert @user.can_delete?("User")
  end

  test "can_manage? should return true when user has manage permission" do
    role = Role.create!(name: "test_role")
    permission = Permission.find_by(resource_type: "User", action: "manage")
    role.permissions << permission
    @user.roles << role

    assert @user.can_manage?("User")
  end

  test "can_manage? should return false when user has only read permission" do
    role = Role.create!(name: "test_role")
    permission = Permission.find_by(resource_type: "User", action: "read")
    role.permissions << permission
    @user.roles << role

    assert_not @user.can_manage?("User")
  end

  test "should work with multiple roles and permissions" do
    role1 = Role.create!(name: "role1")
    role2 = Role.create!(name: "role2")

    permission1 = Permission.find_by(resource_type: "User", action: "read")
    permission2 = Permission.find_by(resource_type: "Project", action: "write")

    role1.permissions << permission1
    role2.permissions << permission2

    @user.roles << [role1, role2]

    assert @user.can_read?("User")
    assert @user.can_write?("Project")
    assert_not @user.can_write?("User")
    assert_not @user.can_read?("Project")
  end
end
