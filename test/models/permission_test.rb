require "test_helper"

class PermissionTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    @permission = Permission.new(resource_type: "User", action: "read", description: "Read user data")
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
    Permission.destroy_all
    assert @permission.valid?
  end

  test "should require resource_type" do
    @permission.resource_type = nil
    assert_not @permission.valid?
    assert_includes @permission.errors[:resource_type], "can't be blank"
  end

  test "should require action" do
    @permission.action = nil
    assert_not @permission.valid?
    assert_includes @permission.errors[:action], "can't be blank"
  end

  test "should validate resource_type inclusion" do
    @permission.resource_type = "InvalidType"
    assert_not @permission.valid?
    assert_includes @permission.errors[:resource_type], "is not included in the list"
  end

  test "should validate action inclusion" do
    @permission.action = "invalid_action"
    assert_not @permission.valid?
    assert_includes @permission.errors[:action], "is not included in the list"
  end

  test "should require unique combination of resource_type and action" do
    Permission.find_by(resource_type: "User", action: "read")
    @permission.resource_type = "User"
    @permission.action = "read"
    assert_not @permission.valid?
    assert_includes @permission.errors[:resource_type], "has already been taken"
  end

  test "should allow same action for different resource_types" do
    Permission.where(resource_type: "Project").destroy_all
    Permission.where(resource_type: "User").destroy_all
    Permission.create!(resource_type: "User", action: "read")

    @permission.resource_type = "Project"
    @permission.action = "read"
    assert @permission.valid?
  end

  test "should allow different actions for same resource_type" do
    Permission.where(resource_type: "User").destroy_all
    Permission.create!(resource_type: "User", action: "read")
    @permission.resource_type = "User"
    @permission.action = "write"
    assert @permission.valid?
  end

  test "should have many roles through role_permissions" do
    permission = Permission.find_by(resource_type: "User", action: "read")
    role = Role.create!(name: "test_role")

    permission.roles << role
    assert_includes permission.roles, role
  end

  test "should destroy dependent role_permissions when destroyed" do
    Permission.destroy_all
    permission = Permission.create!(resource_type: "User", action: "read")
    role = Role.create!(name: "test_role")
    RolePermission.create!(role: role, permission: permission)

    assert_difference "RolePermission.count", -1 do
      permission.destroy
    end
  end

  test "for_resource scope should return permissions for specific resource type" do
    user_permission = Permission.find_by(resource_type: "User", action: "read")
    project_permission = Permission.find_by(resource_type: "Project", action: "read")

    user_permissions = Permission.for_resource("User")
    assert_includes user_permissions, user_permission
    assert_not_includes user_permissions, project_permission
  end

  test "name method should return formatted name" do
    permission = Permission.find_by(resource_type: "User", action: "read")
    assert_equal "read_user", permission.name
  end

  test "should accept all valid resource types" do
    Permission.destroy_all
    Permission::RESOURCE_TYPES.each do |resource_type|
      permission = Permission.new(resource_type: resource_type, action: "read")
      assert permission.valid?, "#{resource_type} should be valid"
    end
  end

  test "should accept all valid actions" do
    Permission.destroy_all
    Permission::ACTIONS.each do |action|
      permission = Permission.new(resource_type: "User", action: action)
      assert permission.valid?, "#{action} should be valid"
    end
  end
end
