namespace :test do
  desc "Run task domain tests (Task, Comment, Event models + controllers + services)"
  task :task do
    $LOAD_PATH << "test"
    Rails::TestUnit::Runner.run([
      "test/models/task_test.rb",
      "test/models/comment_test.rb",
      "test/models/event_test.rb",
      "test/models/task_series_test.rb",
      "test/controllers/tasks_controller_test.rb",
      "test/controllers/tasks",
      "test/services/events"
    ])
  end

  desc "Run project domain tests (Project, ProjectMember models + controllers)"
  task :project do
    $LOAD_PATH << "test"
    Rails::TestUnit::Runner.run([
      "test/models/project_test.rb",
      "test/models/project_member_test.rb",
      "test/controllers/projects_controller_test.rb",
      "test/controllers/projects"
    ])
  end

  desc "Run auth domain tests (User, sessions, passwords, email, TOTP)"
  task :auth do
    $LOAD_PATH << "test"
    Rails::TestUnit::Runner.run([
      "test/models/user_test.rb",
      "test/controllers/sessions_controller_test.rb",
      "test/controllers/passwords_controller_test.rb",
      "test/controllers/password_resets_controller_test.rb",
      "test/controllers/email_verifications_controller_test.rb",
      "test/controllers/emails_controller_test.rb",
      "test/controllers/users_controller_test.rb",
      "test/controllers/totp"
    ])
  end

  desc "Run suggestion domain tests (Suggestion models + services + controllers)"
  task :suggestion do
    $LOAD_PATH << "test"
    Rails::TestUnit::Runner.run([
      "test/models/suggestion_session_test.rb",
      "test/models/suggestion_request_test.rb",
      "test/models/suggestion_response_test.rb",
      "test/models/suggestion_outcome_test.rb",
      "test/models/suggestion_config_test.rb",
      "test/models/suggestion_config_entry_test.rb",
      "test/models/suggested_task_test.rb",
      "test/models/prompt_test.rb",
      "test/models/prompt_set_test.rb",
      "test/services/suggestion_llm_service_test.rb",
      "test/services/suggestion_llm_response_validator_test.rb",
      "test/services/suggestion_outcome_service_test.rb",
      "test/services/suggestion_routing_service_test.rb",
      "test/controllers/tasks/suggestions_controller_test.rb",
      "test/controllers/tasks/suggestions"
    ])
  end

  desc "Run admin domain tests (Admin API controllers + roles/permissions models)"
  task :admin do
    $LOAD_PATH << "test"
    Rails::TestUnit::Runner.run([
      "test/models/role_test.rb",
      "test/models/permission_test.rb",
      "test/models/role_permission_test.rb",
      "test/models/user_role_test.rb",
      "test/models/admin_login_history_test.rb",
      "test/models/system_roles_permissions_test.rb",
      "test/controllers/admin_controller_test.rb",
      "test/controllers/api/v1/admin",
      "test/controllers/concerns/authorization_test.rb"
    ])
  end

  desc "Run LLM domain tests (LLM models + clients + services)"
  task :llm do
    $LOAD_PATH << "test"
    Rails::TestUnit::Runner.run([
      "test/models/llm_model_test.rb",
      "test/models/llm_provider_test.rb",
      "test/lib/llm_client",
      "test/services/llm_client_factory_test.rb",
      "test/services/model_list_service_test.rb"
    ])
  end
end
