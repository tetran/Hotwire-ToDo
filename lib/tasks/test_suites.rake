# NOTE: Always use `Rails::TestUnit::Runner.run_from_rake` here, NOT `.run`.
# `.run` executes in-process via at_exit, inheriting the fully-loaded Rails
# environment from `:environment`, which breaks session/request handling and
# causes ALL controller tests to return 403 Forbidden. `run_from_rake` spawns
# `rails test` as a subprocess so tests run in a clean environment.
# See docs/conventions/TESTING.md "Maintaining Test Suites".
namespace :test do
  desc "Run task domain tests (Task, Comment, Event models + controllers + services)"
  task task: :environment do
    Rails::TestUnit::Runner.run_from_rake("test", [
      "test/models/task_test.rb",
      "test/models/comment_test.rb",
      "test/models/event_test.rb",
      "test/models/task_series_test.rb",
      "test/models/recurrence_rule_test.rb",
      "test/controllers/tasks_controller_test.rb",
      "test/controllers/tasks",
      "test/services/events",
    ])
  end

  desc "Run project domain tests (Project, ProjectMember models + controllers)"
  task project: :environment do
    Rails::TestUnit::Runner.run_from_rake("test", [
      "test/models/project_test.rb",
      "test/models/project_member_test.rb",
      "test/controllers/projects_controller_test.rb",
      "test/controllers/projects",
    ])
  end

  desc "Run auth domain tests (User, sessions, passwords, email, TOTP)"
  task auth: :environment do
    Rails::TestUnit::Runner.run_from_rake("test", [
      "test/models/user_test.rb",
      "test/controllers/sessions_controller_test.rb",
      "test/controllers/passwords_controller_test.rb",
      "test/controllers/password_resets_controller_test.rb",
      "test/controllers/email_verifications_controller_test.rb",
      "test/controllers/emails_controller_test.rb",
      "test/controllers/users_controller_test.rb",
      "test/controllers/totp",
    ])
  end

  desc "Run suggestion domain tests (Suggestion models + services + controllers)"
  task suggestion: :environment do
    Rails::TestUnit::Runner.run_from_rake("test", [
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
      "test/controllers/tasks/suggestions",
    ])
  end

  desc "Run admin domain tests (Admin API controllers + roles/permissions models)"
  task admin: :environment do
    Rails::TestUnit::Runner.run_from_rake("test", [
      "test/models/role_test.rb",
      "test/models/permission_test.rb",
      "test/models/role_permission_test.rb",
      "test/models/user_role_test.rb",
      "test/models/admin_login_history_test.rb",
      "test/models/system_roles_permissions_test.rb",
      "test/models/admin_policy_test.rb",
      "test/controllers/admin_controller_test.rb",
      "test/controllers/api/v1/admin",
      "test/controllers/concerns/authorization_test.rb",
    ])
  end

  desc "Run LLM domain tests (LLM models + clients + services)"
  task llm: :environment do
    Rails::TestUnit::Runner.run_from_rake("test", [
      "test/models/llm_model_test.rb",
      "test/models/llm_provider_test.rb",
      "test/lib/llm_client",
      "test/services/llm_client_factory_test.rb",
      "test/services/model_list_service_test.rb",
    ])
  end

  desc "Run the full test suite: `bin/rails test` followed by `bin/rails test:system`"
  task :all do
    # Shell out so each suite runs in its own clean subprocess.
    # Do NOT chain via Rake::Task#invoke or Runner.run — both share the parent
    # process state and break controller tests (see the NOTE at the top of this file).
    sh "bin/rails test"
    sh "bin/rails test:system"
  end
end
