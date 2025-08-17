require "test_helper"

class AuthorizationTest < ActionDispatch::IntegrationTest
  # Test for authorize_user_read! method
  test "authorize_user_read! should allow access with User:read permission" do
    user = users(:user_manager) # Has User:read permission

    # Create a test controller to test the authorization
    controller = create_test_controller_with_authorization
    controller.current_user = user

    assert_nothing_raised do
      controller.send(:authorize_user_read!)
    end
  end

  test "authorize_user_read! should deny access without User:read permission" do
    user = users(:regular_user) # No User:read permission

    controller = create_test_controller_with_authorization
    controller.current_user = user

    # Should raise an exception or handle authorization failure
    assert_raises(RuntimeError, "Redirect to") do
      controller.send(:authorize_user_read!)
    end
  end

  # Test for authorize_user_write! method
  test "authorize_user_write! should allow access with User:write permission" do
    user = users(:user_manager)  # Has User:write permission

    controller = create_test_controller_with_authorization
    controller.current_user = user

    assert_nothing_raised do
      controller.send(:authorize_user_write!)
    end
  end

  test "authorize_user_write! should deny access without User:write permission" do
    user = users(:regular_user)  # No User:write permission

    controller = create_test_controller_with_authorization
    controller.current_user = user

    assert_raises(RuntimeError) do
      controller.send(:authorize_user_write!)
    end
  end

  # Test for authorize_user_delete! method
  test "authorize_user_delete! should allow access with User:delete permission" do
    user = users(:user_manager)  # Has User:delete permission

    controller = create_test_controller_with_authorization
    controller.current_user = user

    assert_nothing_raised do
      controller.send(:authorize_user_delete!)
    end
  end

  test "authorize_user_delete! should deny access without User:delete permission" do
    user = users(:regular_user)  # No User:delete permission

    controller = create_test_controller_with_authorization
    controller.current_user = user

    assert_raises(RuntimeError) do
      controller.send(:authorize_user_delete!)
    end
  end

  # Test for authorize_admin_read! method
  test "authorize_admin_read! should allow access with Admin:read permission" do
    user = users(:admin_user) # Has Admin:read permission

    controller = create_test_controller_with_authorization
    controller.current_user = user

    assert_nothing_raised do
      controller.send(:authorize_admin_read!)
    end
  end

  test "authorize_admin_read! should deny access without Admin:read permission" do
    user = users(:regular_user) # No Admin:read permission

    controller = create_test_controller_with_authorization
    controller.current_user = user

    assert_raises(RuntimeError) do
      controller.send(:authorize_admin_read!)
    end
  end

  # Test for authorize_admin_write! method
  test "authorize_admin_write! should allow access with Admin:write permission" do
    user = users(:admin_user) # Has Admin:write permission

    controller = create_test_controller_with_authorization
    controller.current_user = user

    assert_nothing_raised do
      controller.send(:authorize_admin_write!)
    end
  end

  test "authorize_admin_write! should deny access without Admin:write permission" do
    user = users(:no_role_user) # No Admin:write permission

    controller = create_test_controller_with_authorization
    controller.current_user = user

    assert_raises(RuntimeError) do
      controller.send(:authorize_admin_write!)
    end
  end

  # Test for authorize_admin_delete! method
  test "authorize_admin_delete! should allow access with Admin:delete permission" do
    user = users(:admin_user) # Has Admin:delete permission

    controller = create_test_controller_with_authorization
    controller.current_user = user

    assert_nothing_raised do
      controller.send(:authorize_admin_delete!)
    end
  end

  test "authorize_admin_delete! should deny access without Admin:delete permission" do
    user = users(:no_role_user) # No Admin:delete permission

    controller = create_test_controller_with_authorization
    controller.current_user = user

    assert_raises(RuntimeError) do
      controller.send(:authorize_admin_delete!)
    end
  end

  private

    def create_test_controller_with_authorization
      # Create a test controller class that includes Authorization concern
      test_controller_class = Class.new(ApplicationController) do
        include Authorization

        attr_accessor :current_user

        def request
          @request ||= ActionDispatch::Request.new({})
        end

        def flash
          @flash ||= ActionDispatch::Flash::FlashHash.new
        end

        def redirect_to(path)
          # Mock redirect for testing
          raise "Redirect to #{path}"
        end
      end

      test_controller_class.new
    end
end
