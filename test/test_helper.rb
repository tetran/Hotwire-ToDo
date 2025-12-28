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
    # Helper methods for login/logout
    def login_as(user, bypass_totp: false)
      # Perform actual login through the login endpoint
      return unless user

      # Set user locale to Japanese for consistent test behavior
      user.update!(locale: "ja")

      if bypass_totp
        # Temporarily disable TOTP to allow login, then re-enable it
        # This approach uses the actual login flow while bypassing TOTP challenge
        original_totp_enabled = user.totp_enabled
        user.update_column(:totp_enabled, false)

        post login_path, params: {
          email: user.email,
          password: "password",
        }
        follow_redirect! while response.redirect?

        # Restore original TOTP setting
        user.update_column(:totp_enabled, original_totp_enabled)
      else
        post login_path, params: {
          email: user.email,
          password: "password", # This matches the fixture password
        }
        # The login should succeed and redirect to the user's inbox project
        # Follow redirects to complete the login process
        follow_redirect! while response.redirect?
      end
    end

    def logout
      reset_session
    end

    # Helper methods for admin tests
    def login_as_admin
      login_as(users(:admin_user))
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
