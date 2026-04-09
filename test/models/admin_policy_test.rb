require "test_helper"

class AdminPolicyTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @policy = AdminPolicy.new(@user)
  end

  test "admin? returns true when user has admin role" do
    admin_role = Role.find_by(name: "admin", system_role: true)
    @user.roles << admin_role

    assert @policy.admin?
  end

  test "admin? returns false when user has no admin role" do
    assert_not @policy.admin?
  end

  test "has_permission? returns true when user has specific permission" do
    role = Role.create!(name: "test_role")
    permission = Permission.find_by(resource_type: "User", action: "read")
    role.permissions << permission
    @user.roles << role

    assert @policy.has_permission?("User", "read")
  end

  test "has_permission? returns false when user lacks the permission" do
    role = Role.create!(name: "test_role")
    @user.roles << role

    assert_not @policy.has_permission?("User", "read")
  end

  test "can_read? returns true with read permission" do
    role = Role.create!(name: "test_role")
    role.permissions << Permission.find_by(resource_type: "User", action: "read")
    @user.roles << role

    assert @policy.can_read?("User")
  end

  test "can_read? returns true with manage permission" do
    role = Role.create!(name: "test_role")
    role.permissions << Permission.find_by(resource_type: "User", action: "manage")
    @user.roles << role

    assert @policy.can_read?("User")
  end

  test "can_read? returns false with only write permission" do
    role = Role.create!(name: "test_role")
    role.permissions << Permission.find_by(resource_type: "User", action: "write")
    @user.roles << role

    assert_not @policy.can_read?("User")
  end

  test "can_write? returns true with write permission" do
    role = Role.create!(name: "test_role")
    role.permissions << Permission.find_by(resource_type: "User", action: "write")
    @user.roles << role

    assert @policy.can_write?("User")
  end

  test "can_write? returns true with manage permission" do
    role = Role.create!(name: "test_role")
    role.permissions << Permission.find_by(resource_type: "User", action: "manage")
    @user.roles << role

    assert @policy.can_write?("User")
  end

  test "can_delete? returns true with delete permission" do
    role = Role.create!(name: "test_role")
    role.permissions << Permission.find_by(resource_type: "User", action: "delete")
    @user.roles << role

    assert @policy.can_delete?("User")
  end

  test "can_delete? returns true with manage permission" do
    role = Role.create!(name: "test_role")
    role.permissions << Permission.find_by(resource_type: "User", action: "manage")
    @user.roles << role

    assert @policy.can_delete?("User")
  end

  test "can_manage? returns true with manage permission" do
    role = Role.create!(name: "test_role")
    role.permissions << Permission.find_by(resource_type: "User", action: "manage")
    @user.roles << role

    assert @policy.can_manage?("User")
  end

  test "can_manage? returns false with only read permission" do
    role = Role.create!(name: "test_role")
    role.permissions << Permission.find_by(resource_type: "User", action: "read")
    @user.roles << role

    assert_not @policy.can_manage?("User")
  end
end
