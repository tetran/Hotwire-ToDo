# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

Rails.logger.debug "Creating roles and permissions..."

# Create permissions first
permissions_data = [
  # User permissions
  { resource_type: "User", action: "read", description: "ユーザー情報の閲覧" },
  { resource_type: "User", action: "write", description: "ユーザー情報の編集" },
  { resource_type: "User", action: "delete", description: "ユーザーの削除" },
  { resource_type: "User", action: "manage", description: "ユーザーの完全管理" },

  # Project permissions
  { resource_type: "Project", action: "read", description: "プロジェクトの閲覧" },
  { resource_type: "Project", action: "write", description: "プロジェクトの編集" },
  { resource_type: "Project", action: "delete", description: "プロジェクトの削除" },
  { resource_type: "Project", action: "manage", description: "プロジェクトの完全管理" },

  # Task permissions
  { resource_type: "Task", action: "read", description: "タスクの閲覧" },
  { resource_type: "Task", action: "write", description: "タスクの編集" },
  { resource_type: "Task", action: "delete", description: "タスクの削除" },
  { resource_type: "Task", action: "manage", description: "タスクの完全管理" },

  # Comment permissions
  { resource_type: "Comment", action: "read", description: "コメントの閲覧" },
  { resource_type: "Comment", action: "write", description: "コメントの編集" },
  { resource_type: "Comment", action: "delete", description: "コメントの削除" },
  { resource_type: "Comment", action: "manage", description: "コメントの完全管理" },

  # Admin permissions（read のみ有効）
  { resource_type: "Admin", action: "read", description: "管理画面の閲覧" },

  # LlmProvider permissions
  { resource_type: "LlmProvider", action: "read", description: "LLMプロバイダ情報の閲覧" },
  { resource_type: "LlmProvider", action: "write", description: "LLMプロバイダ情報の編集" },
  { resource_type: "LlmProvider", action: "delete", description: "LLMプロバイダの削除" },
]

permissions_data.each do |perm_attrs|
  Permission.find_or_create_by!(
    resource_type: perm_attrs[:resource_type],
    action: perm_attrs[:action],
  ) do |permission|
    permission.description = perm_attrs[:description]
  end
end

Rails.logger.debug { "Created #{Permission.count} permissions" }

# Create system roles
admin_role = Role.find_or_create_by!(name: "admin", system_role: true) do |role|
  role.description = "システム管理者（全ての権限を持つ）"
end

user_manager_role = Role.find_or_create_by!(name: "user_manager", system_role: true) do |role|
  role.description = "ユーザー管理者（ユーザーとロールの管理）"
end

user_viewer_role = Role.find_or_create_by!(name: "user_viewer", system_role: true) do |role|
  role.description = "ユーザー閲覧者（ユーザー情報の閲覧のみ）"
end

project_manager_role = Role.find_or_create_by!(name: "project_manager", system_role: true) do |role|
  role.description = "プロジェクト管理者（プロジェクトとタスクの管理）"
end

llm_admin_role = Role.find_or_create_by!(name: "llm_admin", system_role: true) do |role|
  role.description = "LLM設定管理者（LLM関連機能の管理）"
end

Rails.logger.debug { "Created #{Role.count} roles" }

# Assign permissions to roles
Rails.logger.debug "Assigning permissions to roles..."

# Admin role gets all permissions
admin_role.permissions = Permission.all

# User manager gets user management permissions and admin read access only
user_manager_permissions = Permission.where(
  resource_type: "User", action: %w[read write delete],
).or(Permission.where(resource_type: "Admin", action: "read"))
user_manager_role.permissions = user_manager_permissions

# User viewer gets read access to users and admin read access
user_viewer_permissions = Permission.where(
  resource_type: "User", action: "read",
).or(Permission.where(resource_type: "Admin", action: "read"))
user_viewer_role.permissions = user_viewer_permissions

# Project manager gets project and task management with admin read access
project_manager_permissions = Permission.where(
  resource_type: %w[Project Task Comment],
).or(Permission.where(resource_type: "Admin", action: "read"))
project_manager_role.permissions = project_manager_permissions

# LLM admin gets admin read access and LlmProvider permissions
llm_admin_permissions = Permission.where(resource_type: "Admin", action: "read")
                                  .or(Permission.where(resource_type: "LlmProvider"))
llm_admin_role.permissions = llm_admin_permissions

Rails.logger.debug "Assigned permissions to roles"

# Create admin users based on environment
if Rails.env.local?
  # Development environment - create default admin
  admin_user = User.find_or_create_by!(email: "admin@example.com") do |user|
    user.password = "password"
    user.name = "Admin User"
  end

  # Assign admin role to the admin user
  admin_user.roles << admin_role unless admin_user.roles.include?(admin_role)

  # E2E テスト用のユーザーを作成
  viewer_user = User.find_or_create_by!(email: "viewer@example.com") do |user|
    user.password = "password"
    user.name = "Viewer User"
  end
  viewer_user.roles << user_viewer_role unless viewer_user.roles.include?(user_viewer_role)

  llm_admin_user = User.find_or_create_by!(email: "llmadmin@example.com") do |user|
    user.password = "password"
    user.name = "LLM Admin User"
  end
  llm_admin_user.roles << llm_admin_role unless llm_admin_user.roles.include?(llm_admin_role)

  Rails.logger.debug "Created admin user: admin@example.com (password: password)"
  Rails.logger.debug "Created viewer user: viewer@example.com (password: password)"
  Rails.logger.debug "Created llm_admin user: llmadmin@example.com (password: password)"
elsif Rails.env.production?
  # Production/Staging environment - create master user with environment variables
  master_email = ENV.fetch("MASTER_USER_EMAIL", nil)
  master_password = ENV.fetch("MASTER_USER_PASSWORD", nil)

  if master_email.present? && master_password.present?
    master_user = User.find_or_create_by!(email: master_email) do |user|
      user.password = master_password
      user.password_confirmation = master_password
      user.name = ENV["MASTER_USER_NAME"] || "Master Admin"
    end

    # Assign admin role to the master user
    master_user.roles << admin_role unless master_user.roles.include?(admin_role)

    Rails.logger.debug { "Created master user: #{master_email}" }
    Rails.logger.debug "Note: Password was set from MASTER_USER_PASSWORD environment variable"
  else
    Rails.logger.debug "WARNING: Master user not created in production environment"
    Rails.logger.debug "Please set the following environment variables:"
    Rails.logger.debug "- MASTER_USER_EMAIL: Email address for master admin user"
    Rails.logger.debug "- MASTER_USER_PASSWORD: Secure password for master admin user"
    Rails.logger.debug "- MASTER_USER_NAME: Display name for master admin user (optional)"
    Rails.logger.debug ""
    Rails.logger.debug "Then run: bin/rails db:seed"
  end
end

# Create LLM Providers
Rails.logger.debug "Creating LLM providers..."

llm_providers_data = [
  {
    name: "OpenAI",
    api_key: ENV["OPENAI_ACCESS_TOKEN"] || "dummy_key_for_development",
    organization_id: ENV.fetch("OPENAI_ORGANIZATION_ID", nil),
    active: true,
  },
  {
    name: "Anthropic",
    api_key: ENV["ANTHROPIC_API_KEY"] || "dummy_key_for_development",
    active: true,
  },
  {
    name: "Gemini",
    api_key: ENV["GEMINI_API_KEY"] || "dummy_key_for_development",
    active: true,
  },
]

llm_providers_data.each do |provider_attrs|
  LlmProvider.find_or_create_by!(name: provider_attrs[:name]) do |provider|
    provider.api_key = provider_attrs[:api_key]
    provider.organization_id = provider_attrs[:organization_id]
    provider.active = provider_attrs[:active]
  end
end

Rails.logger.debug { "Created #{LlmProvider.count} LLM providers" }

# Create default prompt set for task suggestions
Rails.logger.debug "Creating default prompt set..."

default_prompt_set = PromptSet.find_or_create_by!(name: "default_task_suggestion_v1") do |prompt_set|
  prompt_set.active = true
end

default_prompts_data = [
  {
    position: 1,
    role: "system",
    body: <<~PROMPT.strip,
      You are a professional and friendly strategy consultant who helps clients achieve their goals.
      As you can speak any language and are very kind, you respond in the same language as the client.
    PROMPT
  },
  {
    position: 2,
    role: "user",
    body: <<~PROMPT.strip,
      Please break down what is needed to accomplish the goal below into tasks (Up to 10) with fine granularity.
      ### Client's Goal
      * Goal: {{goal}}
      * Start date: {{start_date}}
      * Overall due date: {{due_date}}
      ### Restriction
      * Responses MUST be in JSON with the format: {"tasks":[{"name":"{name (Up to 100 characters)}","description":"{What, why and how(Even a beginner can understand. Up to 200 characters)}","due_date":"{yyyy/mm/dd}"}]}
      * Responses MUST be in the same language as the client's.
      * Tasks MUST be specific and able to be judged yes/no as to whether they are completed or not.
      * If the goal contains emoji, task names SHOULD contain emojis too.
      * A realistic due date SHOULD be set for each task.
      * If the overall due date ({{due_date}}) is not realistic, ignore it and suggest a realistic due date.
      * There MUST be at least one task with a due date on the last day
      * Other contexts to be considered: {{context}}
    PROMPT
  },
]

default_prompts_data.each do |prompt_attrs|
  prompt = default_prompt_set.prompts.find_or_initialize_by(position: prompt_attrs[:position])
  prompt.role = prompt_attrs[:role]
  prompt.body = prompt_attrs[:body]
  prompt.save!
end

# Keep this seed-managed prompt set consistent across repeated runs.
default_prompt_set.prompts.where.not(position: default_prompts_data.pluck(:position)).destroy_all

Rails.logger.debug do
  "Created default prompt set: #{default_prompt_set.name} (#{default_prompt_set.prompts.count} prompts)"
end

# Create default SuggestionConfig (if none exists)
Rails.logger.debug "Creating default suggestion config..."

unless SuggestionConfig.exists?
  openai_provider = LlmProvider.find_by(name: "OpenAI")
  if openai_provider
    # Find or create gpt-4.1-mini model
    default_model = openai_provider.llm_models.find_or_create_by!(name: "gpt-4.1-mini") do |model|
      model.display_name = "GPT-4.1 Mini"
      model.active = true
    end

    SuggestionConfig.create_with_entries!(
      entries_attributes: [
        { llm_model_id: default_model.id, prompt_set_id: default_prompt_set.id, weight: 100 },
      ],
    )
    Rails.logger.debug { "Created default suggestion config (OpenAI gpt-4.1-mini + #{default_prompt_set.name})" }
  else
    Rails.logger.debug "WARNING: OpenAI provider not found, skipping default suggestion config"
  end
end

Rails.logger.debug "Seed data creation completed!"
Rails.logger.debug "Summary:"
Rails.logger.debug { "- Permissions: #{Permission.count}" }
Rails.logger.debug { "- Roles: #{Role.count}" }
Rails.logger.debug { "- System roles: #{Role.system_roles.count}" }
Rails.logger.debug { "- Custom roles: #{Role.custom_roles.count}" }
Rails.logger.debug { "- LLM Providers: #{LlmProvider.count}" }
Rails.logger.debug { "- Prompt Sets: #{PromptSet.count}" }
Rails.logger.debug { "- Prompts: #{Prompt.count}" }
Rails.logger.debug { "- Suggestion Configs: #{SuggestionConfig.count}" }
