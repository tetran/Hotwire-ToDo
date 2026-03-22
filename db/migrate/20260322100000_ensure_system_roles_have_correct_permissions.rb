class EnsureSystemRolesHaveCorrectPermissions < ActiveRecord::Migration[8.1]
  # 正規の権限セット（seeds.rb と同一）
  CANONICAL_PERMISSIONS = [
    { resource_type: "User", action: "read", description: "ユーザー情報の閲覧" },
    { resource_type: "User", action: "write", description: "ユーザー情報の編集" },
    { resource_type: "User", action: "delete", description: "ユーザーの削除" },
    { resource_type: "User", action: "manage", description: "ユーザーの完全管理" },
    { resource_type: "Project", action: "read", description: "プロジェクトの閲覧" },
    { resource_type: "Project", action: "write", description: "プロジェクトの編集" },
    { resource_type: "Project", action: "delete", description: "プロジェクトの削除" },
    { resource_type: "Project", action: "manage", description: "プロジェクトの完全管理" },
    { resource_type: "Task", action: "read", description: "タスクの閲覧" },
    { resource_type: "Task", action: "write", description: "タスクの編集" },
    { resource_type: "Task", action: "delete", description: "タスクの削除" },
    { resource_type: "Task", action: "manage", description: "タスクの完全管理" },
    { resource_type: "Comment", action: "read", description: "コメントの閲覧" },
    { resource_type: "Comment", action: "write", description: "コメントの編集" },
    { resource_type: "Comment", action: "delete", description: "コメントの削除" },
    { resource_type: "Comment", action: "manage", description: "コメントの完全管理" },
    { resource_type: "Admin", action: "read", description: "管理画面の閲覧" },
    { resource_type: "LlmProvider", action: "read", description: "LLMプロバイダ情報の閲覧" },
    { resource_type: "LlmProvider", action: "write", description: "LLMプロバイダ情報の編集" },
    { resource_type: "LlmProvider", action: "delete", description: "LLMプロバイダの削除" },
  ].freeze

  # 各システムロールに付与すべき権限セット
  SYSTEM_ROLE_PERMISSIONS = {
    "admin" => :all,
    "user_manager" => [
      { resource_type: "User", action: "read" },
      { resource_type: "User", action: "write" },
      { resource_type: "User", action: "delete" },
      { resource_type: "Admin", action: "read" },
    ],
    "user_viewer" => [
      { resource_type: "User", action: "read" },
      { resource_type: "Admin", action: "read" },
    ],
    "project_manager" => [
      { resource_type: "Project", action: "read" },
      { resource_type: "Project", action: "write" },
      { resource_type: "Project", action: "delete" },
      { resource_type: "Project", action: "manage" },
      { resource_type: "Task", action: "read" },
      { resource_type: "Task", action: "write" },
      { resource_type: "Task", action: "delete" },
      { resource_type: "Task", action: "manage" },
      { resource_type: "Comment", action: "read" },
      { resource_type: "Comment", action: "write" },
      { resource_type: "Comment", action: "delete" },
      { resource_type: "Comment", action: "manage" },
      { resource_type: "Admin", action: "read" },
    ],
    "llm_admin" => [
      { resource_type: "Admin", action: "read" },
      { resource_type: "LlmProvider", action: "read" },
      { resource_type: "LlmProvider", action: "write" },
      { resource_type: "LlmProvider", action: "delete" },
    ],
  }.freeze

  def up
    # Step 1: 不足している permission レコードを補完
    now = Time.current.strftime("%Y-%m-%d %H:%M:%S")
    CANONICAL_PERMISSIONS.each do |perm|
      execute <<~SQL
        INSERT INTO permissions (resource_type, action, description, created_at, updated_at)
        VALUES ('#{perm[:resource_type]}', '#{perm[:action]}', '#{perm[:description]}', '#{now}', '#{now}')
        ON CONFLICT (resource_type, action) DO NOTHING
      SQL
    end

    # Step 2: 各システムロールの role_permissions を補完
    SYSTEM_ROLE_PERMISSIONS.each do |role_name, permissions|
      role_id = select_value(
        "SELECT id FROM roles WHERE name = '#{role_name}' AND system_role = TRUE LIMIT 1",
      )
      next unless role_id

      target_permissions = if permissions == :all
        CANONICAL_PERMISSIONS
      else
        permissions
      end

      target_permissions.each do |perm|
        perm_id = select_value(
          "SELECT id FROM permissions WHERE resource_type = '#{perm[:resource_type]}' AND action = '#{perm[:action]}' LIMIT 1",
        )
        next unless perm_id

        execute <<~SQL
          INSERT INTO role_permissions (role_id, permission_id, created_at, updated_at)
          VALUES (#{role_id}, #{perm_id}, '#{now}', '#{now}')
          ON CONFLICT (role_id, permission_id) DO NOTHING
        SQL
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
