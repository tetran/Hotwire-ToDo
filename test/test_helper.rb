require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  add_filter "/test/"
  add_filter "/config/"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require "mocha/minitest"

# Allow local connections but block external HTTP requests during tests
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module ActionDispatch
  class IntegrationTest
    # Test fixture password - must match the password in fixtures
    TEST_PASSWORD = "HoboTest!Str0ng#2024".freeze

    # Helper methods for login/logout
    def login_as(user, bypass_totp: false)
      # Perform actual login through the login endpoint
      return unless user

      # Set user locale to Japanese for consistent test behavior
      user.update!(locale: "ja")

      if bypass_totp && user.totp_enabled?
        # Temporarily disable TOTP for test login
        original_totp_state = user.totp_enabled
        user.update_column(:totp_enabled, false)

        do_login(user)

        # Restore TOTP state
        user.update_column(:totp_enabled, original_totp_state)
      else
        do_login(user)
      end
    end

    def do_login(user)
      post login_path, params: {
        email: user.email,
        password: TEST_PASSWORD,
      }
      # The login should succeed and redirect to the user's inbox project
      # Follow redirects to complete the login process
      follow_redirect! while response.redirect?
    end

    def logout
      reset_session
    end

    # Helper methods for admin tests

    # 一般ログインフロー用。admin API テストでは login_as_admin_api を使うこと
    def login_as_admin
      login_as(users(:admin_user))
    end

    def login_as_admin_api(user = nil, bypass_totp: false)
      user ||= users(:admin_user)
      user.update!(locale: "ja")
      if bypass_totp && user.totp_enabled?
        user.update_column(:totp_enabled, false)
        post api_v1_admin_session_path, params: { email: user.email, password: TEST_PASSWORD }, as: :json
        user.update_column(:totp_enabled, true)
      else
        post api_v1_admin_session_path, params: { email: user.email, password: TEST_PASSWORD }, as: :json
      end
    end

    def login_as_admin_api_read_only
      user = users(:user_viewer)
      post api_v1_admin_session_path, params: { email: user.email, password: TEST_PASSWORD }, as: :json
    end

    def login_as_llm_admin_api
      user = users(:llm_admin_user)
      post api_v1_admin_session_path, params: { email: user.email, password: TEST_PASSWORD }, as: :json
    end

    def login_as_user_manager
      login_as(users(:user_manager))
    end

    def login_as_regular_user
      login_as(users(:regular_user))
    end

    def assert_admin_access_required
      assert_redirected_to root_path
      # NOTE: Flash message assertion might need adjustment based on actual implementation
    end
  end
end
