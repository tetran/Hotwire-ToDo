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

  # owned_permission_ids / can_grant_permissions? pinned contract tests

  test "owned_permission_ids returns distinct ids for a user with multiple roles sharing a permission" do
    shared_perm = Permission.find_by(resource_type: "User", action: "read")
    role_a = Role.create!(name: "test_role_a")
    role_b = Role.create!(name: "test_role_b")
    role_a.permissions << shared_perm
    role_b.permissions << shared_perm
    @user.roles << role_a
    @user.roles << role_b

    ids = @policy.owned_permission_ids
    assert_equal ids.uniq, ids
    assert_includes ids, shared_perm.id
  end

  test "can_grant_permissions? returns true when all ids are owned, Integer input" do
    perm_read  = Permission.find_by(resource_type: "User", action: "read")
    perm_write = Permission.find_by(resource_type: "User", action: "write")
    role = Role.create!(name: "test_role_int")
    role.permissions << perm_read
    role.permissions << perm_write
    @user.roles << role

    assert @policy.can_grant_permissions?([perm_read.id, perm_write.id])
  end

  test "can_grant_permissions? returns true when all ids are owned, String input" do
    perm_read  = Permission.find_by(resource_type: "User", action: "read")
    perm_write = Permission.find_by(resource_type: "User", action: "write")
    role = Role.create!(name: "test_role_str")
    role.permissions << perm_read
    role.permissions << perm_write
    @user.roles << role

    assert @policy.can_grant_permissions?([perm_read.id.to_s, perm_write.id.to_s])
  end

  test "can_grant_permissions? returns false when any id is not owned, String input" do
    perm_read = Permission.find_by(resource_type: "User", action: "read")
    role = Role.create!(name: "test_role_neg")
    role.permissions << perm_read
    @user.roles << role

    assert_not @policy.can_grant_permissions?([perm_read.id.to_s, "99999"])
  end

  test "can_grant_permissions? returns true on empty input (nil, [], and [''])" do
    assert @policy.can_grant_permissions?(nil)
    assert @policy.can_grant_permissions?([])
    assert @policy.can_grant_permissions?([""])
  end
end
