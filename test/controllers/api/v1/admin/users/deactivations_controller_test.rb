require "test_helper"

module Api
  module V1
    module Admin
      module Users
        class DeactivationsControllerTest < ActionDispatch::IntegrationTest
          # ---------------------------------------------------------------
          # Auth 4-pattern: unauthenticated → 401, regular user → 401,
          # admin without User:write → 403, admin with User:write → 204
          # ---------------------------------------------------------------
          test "POST create returns 401 when not logged in" do
            target = users(:regular_user)
            post api_v1_admin_user_deactivation_path(target)
            assert_response :unauthorized
            assert_equal "Unauthorized", response.parsed_body["error"]
          end

          test "POST create returns 401 when logged in as regular user" do
            login_as(users(:regular_user))
            target = users(:no_role_user)
            post api_v1_admin_user_deactivation_path(target)
            assert_response :unauthorized
            assert_equal "Unauthorized", response.parsed_body["error"]
          end

          test "POST create returns 403 when admin lacks User:write capability" do
            login_as_admin_api_read_only # user_viewer: User:read only
            target = users(:regular_user)
            post api_v1_admin_user_deactivation_path(target)
            assert_response :forbidden
          end

          test "POST create returns 204 and calls service when admin has User:write" do
            login_as_admin_api
            target = users(:regular_user)
            Account::DeactivationService.expects(:call).with(
              user: target,
              performer: users(:admin_user),
              reason: nil,
              self_deactivated: false,
            ).returns(true)
            post api_v1_admin_user_deactivation_path(target), params: { reason: nil }, as: :json
            assert_response :no_content
          end

          test "POST create passes reason param to service" do
            login_as_admin_api
            target = users(:regular_user)
            Account::DeactivationService.expects(:call).with(
              user: target,
              performer: users(:admin_user),
              reason: "Violated terms",
              self_deactivated: false,
            ).returns(true)
            post api_v1_admin_user_deactivation_path(target),
                 params: { reason: "Violated terms" }, as: :json
            assert_response :no_content
          end

          test "POST create returns 404 when target is an admin account" do
            login_as_admin_api
            admin_target = users(:user_manager)
            Account::DeactivationService.expects(:call).never
            post api_v1_admin_user_deactivation_path(admin_target)
            assert_response :not_found
          end

          test "POST create returns 404 when deactivating own admin account" do
            login_as_admin_api
            own_account = users(:admin_user)
            Account::DeactivationService.expects(:call).never
            post api_v1_admin_user_deactivation_path(own_account)
            assert_response :not_found
          end

          test "POST create returns 404 for non-existent user" do
            login_as_admin_api
            Account::DeactivationService.expects(:call).never
            post api_v1_admin_user_deactivation_path(user_id: 0)
            assert_response :not_found
          end

          test "POST create returns 404 (not 500) when target is already deactivated" do
            login_as_admin_api
            target = users(:regular_user)
            DeactivatedUser.create!(
              user: target,
              original_email: target.email,
              deactivated_at: Time.current,
            )

            Account::DeactivationService.expects(:call).never
            post api_v1_admin_user_deactivation_path(target)
            assert_response :not_found
          end

          test "POST create returns 422 with errors when service raises RecordInvalid" do
            login_as_admin_api
            target = users(:regular_user)
            error_record = DeactivatedUser.new
            error_record.errors.add(:base, "Validation failed")
            Account::DeactivationService.expects(:call).raises(
              ActiveRecord::RecordInvalid.new(error_record),
            )
            post api_v1_admin_user_deactivation_path(target), as: :json
            assert_response :unprocessable_entity
            assert response.parsed_body.key?("errors")
          end

          test "POST create succeeds when user_manager calls it" do
            login_as_admin_api(users(:user_manager))
            target = users(:regular_user)
            Account::DeactivationService.expects(:call).with(
              user: target,
              performer: users(:user_manager),
              reason: nil,
              self_deactivated: false,
            ).returns(true)
            post api_v1_admin_user_deactivation_path(target), as: :json
            assert_response :no_content
          end
        end
      end
    end
  end
end
