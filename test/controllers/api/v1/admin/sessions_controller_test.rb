require "test_helper"

module Api
  module V1
    module Admin
      class SessionsControllerTest < ActionDispatch::IntegrationTest
        # show
        test "GET show returns 401 when not logged in" do
          get api_v1_admin_session_path
          assert_response :unauthorized
          json = response.parsed_body
          assert_equal "Unauthorized", json["error"]
        end

        test "GET show returns user info when logged in as admin" do
          user = users(:admin_user)
          login_as_admin_api(user)
          get api_v1_admin_session_path
          assert_response :success
          json = response.parsed_body
          assert_equal user.id, json["user"]["id"]
          assert_equal user.email, json["user"]["email"]
          assert_equal user.name, json["user"]["name"]
        end

        # create
        test "POST create returns 401 with invalid credentials" do
          post api_v1_admin_session_path, params: { email: "wrong@example.com", password: "wrong" },
                                          as: :json
          assert_response :unauthorized
          json = response.parsed_body
          assert_equal "Invalid email or password", json["error"]
        end

        test "POST create returns 401 when regular user logs in (no Admin:read)" do
          user = users(:regular_user)
          post api_v1_admin_session_path, params: { email: user.email, password: "password" },
                                          as: :json
          assert_response :unauthorized
          json = response.parsed_body
          assert_equal "Invalid email or password", json["error"]
        end

        test "POST create returns user info when admin logs in without TOTP" do
          user = users(:admin_user)
          post api_v1_admin_session_path, params: { email: user.email, password: "password" },
                                          as: :json
          assert_response :success
          json = response.parsed_body
          assert_equal user.id, json["user"]["id"]
          assert_equal user.email, json["user"]["email"]
          assert_equal user.name, json["user"]["name"]
          assert_equal user.id, session[:admin_user_id]
        end

        test "POST create returns totp_required when admin with TOTP enabled logs in without code" do
          user = users(:admin_totp_user)
          post api_v1_admin_session_path, params: { email: user.email, password: "password" },
                                          as: :json
          assert_response :ok
          json = response.parsed_body
          assert json["totp_required"]
          assert_nil session[:admin_user_id]
          assert_equal user.id, session[:admin_pending_user_id]
        end

        test "POST create with valid TOTP code completes login via pending challenge (2-step)" do
          user = users(:admin_totp_user)
          # Step 1: credential check
          post api_v1_admin_session_path,
               params: { email: user.email, password: "password" },
               as: :json
          assert_response :ok
          assert session[:admin_pending_user_id]
          # Step 2: TOTP challenge (credentials not required)
          totp = ROTP::TOTP.new(user.totp_secret, issuer: "Hobo Todo")
          valid_code = totp.now
          post api_v1_admin_session_path,
               params: { totp_code: valid_code },
               as: :json
          assert_response :success
          json = response.parsed_body
          assert_equal user.id, json["user"]["id"]
          assert_equal user.id, session[:admin_user_id]
          assert_nil session[:admin_pending_user_id]
        end

        test "POST create with invalid TOTP code returns 401 and clears pending session" do
          user = users(:admin_totp_user)
          # Step 1
          post api_v1_admin_session_path,
               params: { email: user.email, password: "password" },
               as: :json
          assert_response :ok
          # Step 2: invalid code
          post api_v1_admin_session_path,
               params: { totp_code: "000000" },
               as: :json
          assert_response :unauthorized
          json = response.parsed_body
          assert_equal "Invalid TOTP code", json["error"]
          assert_nil session[:admin_pending_user_id]
        end

        test "POST create with totp_code but no pending session returns 401" do
          post api_v1_admin_session_path,
               params: { totp_code: "123456" },
               as: :json
          assert_response :unauthorized
          json = response.parsed_body
          assert_equal "Invalid email or password", json["error"]
        end

        # セッション分離の検証
        test "POST create as admin does not set session[:user_id]" do
          user = users(:admin_user)
          post api_v1_admin_session_path, params: { email: user.email, password: "password" }, as: :json
          assert_response :success
          assert_nil session[:user_id]
          assert_equal user.id, session[:admin_user_id]
        end

        # destroy
        test "DELETE destroy returns 401 when not logged in" do
          delete api_v1_admin_session_path
          assert_response :unauthorized
        end

        test "DELETE destroy logs out admin user" do
          login_as_admin_api(users(:admin_user))
          delete api_v1_admin_session_path
          assert_response :no_content
          assert_nil session[:admin_user_id]
        end

        test "DELETE destroy does not clear session[:user_id]" do
          login_as(users(:admin_user))
          login_as_admin_api(users(:admin_user))
          delete api_v1_admin_session_path
          assert_response :no_content
          assert_nil session[:admin_user_id]
          assert_not_nil session[:user_id]
        end

        # capabilities + is_admin
        test "POST create returns capabilities and is_admin for admin_user" do
          user = users(:admin_user)
          post api_v1_admin_session_path, params: { email: user.email, password: "password" },
                                          as: :json
          assert_response :success
          json = response.parsed_body
          assert_equal true, json["user"]["is_admin"]
          caps = json["user"]["capabilities"]
          assert_not_nil caps
          assert_equal true, caps["User"]["read"]
          assert_equal true, caps["User"]["write"]
          assert_equal true, caps["LlmProvider"]["read"]
          assert_equal true, caps["LlmProvider"]["write"]
        end

        test "POST create returns limited capabilities for user_viewer" do
          user = users(:user_viewer)
          post api_v1_admin_session_path, params: { email: user.email, password: "password" },
                                          as: :json
          assert_response :success
          json = response.parsed_body
          assert_equal false, json["user"]["is_admin"]
          caps = json["user"]["capabilities"]
          assert_equal true,  caps["User"]["read"]
          assert_equal false, caps["User"]["write"]
          assert_equal false, caps["User"]["delete"]
          assert_equal false, caps["User"]["manage"]
          assert_equal false, caps["LlmProvider"]["read"]
          assert_equal false, caps["LlmProvider"]["write"]
        end

        test "POST create returns LlmProvider capabilities for llm_admin_user" do
          user = users(:llm_admin_user)
          post api_v1_admin_session_path, params: { email: user.email, password: "password" },
                                          as: :json
          assert_response :success
          json = response.parsed_body
          assert_equal false, json["user"]["is_admin"]
          caps = json["user"]["capabilities"]
          assert_equal true,  caps["LlmProvider"]["read"]
          assert_equal true,  caps["LlmProvider"]["write"]
          assert_equal true,  caps["LlmProvider"]["delete"]
          assert_equal false, caps["LlmProvider"]["manage"]
          assert_equal false, caps["User"]["read"]
          assert_equal false, caps["User"]["write"]
        end

        # セッション固定化対策
        test "POST create でログインのたびにセッション ID がローテーションされる" do
          user = users(:admin_user)
          login_as_admin_api(user)
          first_id = session.id.public_id
          delete api_v1_admin_session_path
          post api_v1_admin_session_path, params: { email: user.email, password: TEST_PASSWORD }, as: :json
          assert_response :success
          assert_not_equal first_id, session.id.public_id
        end

        test "DELETE destroy でログアウト時にセッション ID がローテーションされる" do
          login_as_admin_api(users(:admin_user))
          old_id = session.id.public_id
          delete api_v1_admin_session_path
          assert_response :no_content
          assert_not_equal old_id, session.id.public_id
        end

      end
    end
  end
end
