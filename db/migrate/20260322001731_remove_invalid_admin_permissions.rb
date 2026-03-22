class RemoveInvalidAdminPermissions < ActiveRecord::Migration[8.1]
  def up
    # role_permissions の参照を先に削除（モデルレベルの cascade がないため）
    execute <<~SQL
      DELETE FROM role_permissions
      WHERE permission_id IN (
        SELECT id FROM permissions
        WHERE resource_type = 'Admin' AND action IN ('write', 'delete', 'manage')
      )
    SQL
    execute <<~SQL
      DELETE FROM permissions
      WHERE resource_type = 'Admin' AND action IN ('write', 'delete', 'manage')
    SQL
  end

  def down
    execute <<~SQL
      INSERT INTO permissions (resource_type, action, description, created_at, updated_at)
      VALUES
        ('Admin', 'write', '管理画面での編集操作', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('Admin', 'delete', '管理画面での削除操作', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('Admin', 'manage', '管理画面の完全管理', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL
  end
end
