class AddEventLogPermissions < ActiveRecord::Migration[8.1]
  def up
    permission = Permission.find_or_create_by!(
      resource_type: "EventLog",
      action: "read",
    ) do |p|
      p.description = "Read event logs"
    end

    admin_role = Role.find_by(name: "admin")
    admin_role.permissions << permission if admin_role && !admin_role.permissions.exists?(id: permission.id)
  end

  def down
    permission = Permission.find_by(resource_type: "EventLog", action: "read")
    return unless permission

    RolePermission.where(permission: permission).delete_all
    permission.destroy
  end
end
