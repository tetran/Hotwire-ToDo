# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Creating roles and permissions..."

# Create permissions first
permissions_data = [
  # User permissions
  { resource_type: 'User', action: 'read', description: 'ユーザー情報の閲覧' },
  { resource_type: 'User', action: 'write', description: 'ユーザー情報の編集' },
  { resource_type: 'User', action: 'delete', description: 'ユーザーの削除' },
  { resource_type: 'User', action: 'manage', description: 'ユーザーの完全管理' },
  
  # Project permissions
  { resource_type: 'Project', action: 'read', description: 'プロジェクトの閲覧' },
  { resource_type: 'Project', action: 'write', description: 'プロジェクトの編集' },
  { resource_type: 'Project', action: 'delete', description: 'プロジェクトの削除' },
  { resource_type: 'Project', action: 'manage', description: 'プロジェクトの完全管理' },
  
  # Task permissions
  { resource_type: 'Task', action: 'read', description: 'タスクの閲覧' },
  { resource_type: 'Task', action: 'write', description: 'タスクの編集' },
  { resource_type: 'Task', action: 'delete', description: 'タスクの削除' },
  { resource_type: 'Task', action: 'manage', description: 'タスクの完全管理' },
  
  # Comment permissions
  { resource_type: 'Comment', action: 'read', description: 'コメントの閲覧' },
  { resource_type: 'Comment', action: 'write', description: 'コメントの編集' },
  { resource_type: 'Comment', action: 'delete', description: 'コメントの削除' },
  { resource_type: 'Comment', action: 'manage', description: 'コメントの完全管理' },
  
  # Admin permissions
  { resource_type: 'Admin', action: 'manage', description: '管理画面へのアクセス' }
]

permissions_data.each do |perm_attrs|
  Permission.find_or_create_by!(
    resource_type: perm_attrs[:resource_type],
    action: perm_attrs[:action]
  ) do |permission|
    permission.description = perm_attrs[:description]
  end
end

puts "Created #{Permission.count} permissions"

# Create system roles
admin_role = Role.find_or_create_by!(name: 'admin', system_role: true) do |role|
  role.description = 'システム管理者（全ての権限を持つ）'
end

user_manager_role = Role.find_or_create_by!(name: 'user_manager', system_role: true) do |role|
  role.description = 'ユーザー管理者（ユーザーとロールの管理）'
end

user_viewer_role = Role.find_or_create_by!(name: 'user_viewer', system_role: true) do |role|
  role.description = 'ユーザー閲覧者（ユーザー情報の閲覧のみ）'
end

project_manager_role = Role.find_or_create_by!(name: 'project_manager', system_role: true) do |role|
  role.description = 'プロジェクト管理者（プロジェクトとタスクの管理）'
end

puts "Created #{Role.count} roles"

# Assign permissions to roles
puts "Assigning permissions to roles..."

# Admin role gets all permissions
admin_role.permissions = Permission.all

# User manager gets user management and admin access
user_manager_permissions = Permission.where(
  resource_type: ['User', 'Admin']
)
user_manager_role.permissions = user_manager_permissions

# User viewer gets read access to users and admin access
user_viewer_permissions = Permission.where(
  resource_type: 'User', action: 'read'
).or(Permission.where(resource_type: 'Admin', action: 'manage'))
user_viewer_role.permissions = user_viewer_permissions

# Project manager gets project and task management
project_manager_permissions = Permission.where(
  resource_type: ['Project', 'Task', 'Comment']
).or(Permission.where(resource_type: 'Admin', action: 'manage'))
project_manager_role.permissions = project_manager_permissions

puts "Assigned permissions to roles"

# Create a default admin user if it doesn't exist
if Rails.env.development?
  admin_user = User.find_or_create_by!(email: 'admin@example.com') do |user|
    user.password = 'password'
    user.name = 'Admin User'
  end
  
  # Assign admin role to the admin user
  admin_user.roles << admin_role unless admin_user.roles.include?(admin_role)
  
  puts "Created admin user: admin@example.com (password: password)"
end

puts "Seed data creation completed!"
puts "Summary:"
puts "- Permissions: #{Permission.count}"
puts "- Roles: #{Role.count}"
puts "- System roles: #{Role.system_roles.count}"
puts "- Custom roles: #{Role.custom_roles.count}"
