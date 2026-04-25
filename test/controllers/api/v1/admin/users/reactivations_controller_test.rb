require "test_helper"

module Api
  module V1
    module Admin
      module Users
        class ReactivationsControllerTest < ActionDispatch::IntegrationTest
          # ---------------------------------------------------------------
          # Auth 4-pattern: unauthenticated → 401, regular user → 401,
          # admin without User:write → 403, admin with User:write → 204
          # ---------------------------------------------------------------
          test "POST create returns 401 when not logged in" do
            target = users(:deactivated_user)
            post api_v1_admin_user_reactivation_path(target)
            assert_response :unauthorized
            assert_equal "Unauthorized", response.parsed_body["error"]
          end

          test "POST create returns 401 when logged in as regular user" do
            login_as(users(:regular_user))
            target = users(:deactivated_user)
            post api_v1_admin_user_reactivation_path(target)
            assert_response :unauthorized
            assert_equal "Unauthorized", response.parsed_body["error"]
          end

          test "POST create returns 403 when admin lacks User:write capability" do
            login_as_admin_api_read_only # user_viewer: User:read only
            target = users(:deactivated_user)
            post api_v1_admin_user_reactivation_path(target)
            assert_response :forbidden
          end

          test "POST create returns 204 and calls service when admin has User:write (no new_email)" do
            login_as_admin_api
            target = users(:deactivated_user)
            Account::DeactivationService.expects(:reactivate).with(
              user: target,
              performer: users(:admin_user),
              new_email: nil,
            ).returns(true)
            post api_v1_admin_user_reactivation_path(target), as: :json
            assert_response :no_content
          end

          test "POST create returns 204 and calls service with new_email when provided" do
            login_as_admin_api
            target = users(:deactivated_user)
            Account::DeactivationService.expects(:reactivate).with(
              user: target,
              performer: users(:admin_user),
              new_email: "newaddress@example.com",
            ).returns(true)
            post api_v1_admin_user_reactivation_path(target),
                 params: { new_email: "newaddress@example.com" }, as: :json
            assert_response :no_content
          end

          test "POST create returns 404 when target user is active (not in deactivated scope)" do
            login_as_admin_api
            active_target = users(:regular_user)
            Account::DeactivationService.expects(:reactivate).never
            post api_v1_admin_user_reactivation_path(active_target), as: :json
            assert_response :not_found
          end

          test "POST create returns 404 when target user is an admin account" do
            login_as_admin_api
            admin_target = users(:user_manager)
            Account::DeactivationService.expects(:reactivate).never
            post api_v1_admin_user_reactivation_path(admin_target), as: :json
            assert_response :not_found
          end

          test "POST create returns 404 for non-existent user" do
            login_as_admin_api
            Account::DeactivationService.expects(:reactivate).never
            post api_v1_admin_user_reactivation_path(user_id: 0), as: :json
            assert_response :not_found
          end

          # 422 shapes: new_email omitted → original_email_conflict: true
          test "POST create returns 422 with original_email_conflict when new_email omitted and original is taken" do
            login_as_admin_api
            target = users(:deactivated_user)
            error_record = User.new
            error_record.errors.add(:email, "has already been taken")
            Account::DeactivationService.expects(:reactivate).with(
              user: target,
              performer: users(:admin_user),
              new_email: nil,
            ).raises(ActiveRecord::RecordInvalid.new(error_record))
            post api_v1_admin_user_reactivation_path(target), as: :json
            assert_response :unprocessable_entity
            body = response.parsed_body
            assert body.key?("errors")
            assert_equal true, body["original_email_conflict"]
          end

          # 422 shapes: new_email omitted but error is unrelated to email → no conflict flag
          test "POST create omits original_email_conflict when RecordInvalid error has no email errors" do
            login_as_admin_api
            target = users(:deactivated_user)
            error_record = User.new
            error_record.errors.add(:base, "Some unrelated validation failure")
            Account::DeactivationService.expects(:reactivate).raises(
              ActiveRecord::RecordInvalid.new(error_record),
            )
            post api_v1_admin_user_reactivation_path(target), as: :json
            assert_response :unprocessable_entity
            body = response.parsed_body
            assert body.key?("errors")
            assert_not body.key?("original_email_conflict"),
                       "flag must be tied to email errors, not any RecordInvalid"
          end

          # 422 shapes: new_email provided → NO original_email_conflict key
          test "POST create returns 422 without original_email_conflict when new_email provided and conflicts" do
            login_as_admin_api
            target = users(:deactivated_user)
            error_record = User.new
            error_record.errors.add(:email, "has already been taken")
            Account::DeactivationService.expects(:reactivate).with(
              user: target,
              performer: users(:admin_user),
              new_email: "taken@example.com",
            ).raises(ActiveRecord::RecordInvalid.new(error_record))
            post api_v1_admin_user_reactivation_path(target),
                 params: { new_email: "taken@example.com" }, as: :json
            assert_response :unprocessable_entity
            body = response.parsed_body
            assert body.key?("errors")
            assert_not body.key?("original_email_conflict"),
                       "original_email_conflict must NOT be present when new_email was provided"
          end

          # Regression: concurrent reactivation. Service raises RecordNotFound
          # when the DeactivatedUser row is gone (already destroyed by a
          # competing request). Controller must translate that to 422 with a
          # structured body, not bubble a 404/500.
          test "POST create returns 422 with already_reactivated flag on RecordNotFound from service" do
            login_as_admin_api
            target = users(:deactivated_user)
            Account::DeactivationService.expects(:reactivate).with(
              user: target,
              performer: users(:admin_user),
              new_email: nil,
            ).raises(ActiveRecord::RecordNotFound)
            post api_v1_admin_user_reactivation_path(target), as: :json
            assert_response :unprocessable_entity
            body = response.parsed_body
            assert body.key?("errors")
            assert_equal true, body["already_reactivated"]
          end

          test "POST create succeeds when user_manager calls it" do
            login_as_admin_api(users(:user_manager))
            target = users(:deactivated_user)
            Account::DeactivationService.expects(:reactivate).with(
              user: target,
              performer: users(:user_manager),
              new_email: nil,
            ).returns(true)
            post api_v1_admin_user_reactivation_path(target), as: :json
            assert_response :no_content
          end
        end
      end
    end
  end
end
