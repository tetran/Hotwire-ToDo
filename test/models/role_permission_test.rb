require "test_helper"

class RolePermissionTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    @role = Role.create!(name: "test_role")
    @permission = Permission.find_by(resource_type: "User", action: "read")
    @role_permission = RolePermission.new(role: @role, permission: @permission)
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
    assert @role_permission.valid?
  end

  test "should require role" do
    @role_permission.role = nil
    assert_not @role_permission.valid?
    assert_includes @role_permission.errors[:role], "must exist"
  end

  test "should require permission" do
    @role_permission.permission = nil
    assert_not @role_permission.valid?
    assert_includes @role_permission.errors[:permission], "must exist"
  end

  test "should require unique combination of role and permission" do
    RolePermission.create!(role: @role, permission: @permission)
    duplicate_role_permission = RolePermission.new(role: @role, permission: @permission)

    assert_not duplicate_role_permission.valid?
    assert_includes duplicate_role_permission.errors[:role_id], "has already been taken"
  end

  test "should allow same role with different permissions" do
    permission2 = Permission.find_by(resource_type: "User", action: "write")
    RolePermission.find_by(role: @role, permission: @permission)
    role_permission2 = RolePermission.new(role: @role, permission: permission2)

    assert role_permission2.valid?
  end

  test "should allow same permission with different roles" do
    role2 = Role.create!(name: "another_role")
    RolePermission.find_by(role: @role, permission: @permission)
    role_permission2 = RolePermission.new(role: role2, permission: @permission)

    assert role_permission2.valid?
  end

  test "should belong to role" do
    role_permission = RolePermission.create!(role: @role, permission: @permission)
    assert_equal @role, role_permission.role
  end

  test "should belong to permission" do
    role_permission = RolePermission.create!(role: @role, permission: @permission)
    assert_equal @permission, role_permission.permission
  end
end
