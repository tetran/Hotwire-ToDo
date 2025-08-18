require "test_helper"

class RoleTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    @role = Role.new(name: "test_role", description: "Test role")
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
    assert @role.valid?
  end

  test "should require name" do
    @role.name = nil
    assert_not @role.valid?
    assert_includes @role.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    Role.create!(name: "unique_role")
    @role.name = "unique_role"
    assert_not @role.valid?
    assert_includes @role.errors[:name], "has already been taken"
  end

  test "should default system_role to false" do
    role = Role.create!(name: "default_role")
    assert_not role.system_role
  end

  test "should have many users through user_roles" do
    role = Role.create!(name: "user_role")
    user = User.create!(email: "test@example.com", password: "password123")

    role.users << user
    assert_includes role.users, user
  end

  test "should have many permissions through role_permissions" do
    role = Role.create!(name: "permission_role")
    permission = Permission.find_by(resource_type: "User", action: "read")

    role.permissions << permission
    assert_includes role.permissions, permission
  end

  test "should destroy dependent user_roles when destroyed" do
    role = Role.create!(name: "destroy_role")
    user = User.create!(email: "test2@example.com", password: "password123")
    UserRole.create!(user: user, role: role)

    assert_difference "UserRole.count", -1 do
      role.destroy
    end
  end

  test "should destroy dependent role_permissions when destroyed" do
    role = Role.create!(name: "destroy_role")
    permission = Permission.find_by(resource_type: "User", action: "read")
    RolePermission.create!(role: role, permission: permission)

    assert_difference "RolePermission.count", -1 do
      role.destroy
    end
  end

  test "system_roles scope should return only system roles" do
    system_role = Role.create!(name: "system_admin", system_role: true)
    custom_role = Role.create!(name: "custom_role", system_role: false)

    system_roles = Role.system_roles
    assert_includes system_roles, system_role
    assert_not_includes system_roles, custom_role
  end

  test "custom_roles scope should return only custom roles" do
    system_role = Role.create!(name: "system_admin", system_role: true)
    custom_role = Role.create!(name: "custom_role", system_role: false)

    custom_roles = Role.custom_roles
    assert_includes custom_roles, custom_role
    assert_not_includes custom_roles, system_role
  end

  test "admin class method should find admin role" do
    admin_role = Role.find_by(name: "admin", system_role: true)
    assert_equal admin_role, Role.admin
  end

  test "user_manager class method should find user_manager role" do
    user_manager_role = Role.find_by(name: "user_manager", system_role: true)
    assert_equal user_manager_role, Role.user_manager
  end

  test "user_viewer class method should find user_viewer role" do
    user_viewer_role = Role.create!(name: "user_viewer", system_role: true)
    assert_equal user_viewer_role, Role.user_viewer
  end
end
