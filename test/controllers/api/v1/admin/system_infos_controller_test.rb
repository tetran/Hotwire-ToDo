require "test_helper"

module Api
  module V1
    module Admin
      class SystemInfosControllerTest < ActionDispatch::IntegrationTest
        # 1. Unauthenticated → 401
        test "GET show returns 401 when not logged in" do
          get api_v1_admin_system_info_path
          assert_response :unauthorized
        end

        # 2. Regular user (non-admin session) → 401
        test "GET show returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_system_info_path
          assert_response :unauthorized
        end

        # 3. Admin without Admin:read capability → 403
        test "GET show returns 403 when admin session has no Admin:read" do
          user = users(:admin_user)
          login_as_admin_api(user)
          user.roles.clear
          get api_v1_admin_system_info_path
          assert_response :forbidden
        end

        # 4. Admin with Admin:read → 200 + full JSON shape
        test "GET show returns 200 with system info when logged in as admin" do
          login_as_admin_api
          get api_v1_admin_system_info_path
          assert_response :success
          json = response.parsed_body

          # Top-level keys — no surplus
          assert_equal %w[database environment rails_version ruby_version runtime], json.keys.sort

          assert_equal RUBY_VERSION, json["ruby_version"]
          assert_equal Rails::VERSION::STRING, json["rails_version"]
          assert_equal Rails.env, json["environment"]
        end

        test "GET show database section has correct keys and values" do
          login_as_admin_api
          get api_v1_admin_system_info_path
          assert_response :success
          db = response.parsed_body["database"]

          assert_equal %w[adapter version], db.keys.sort
          assert_kind_of String, db["adapter"]
          assert(db["version"].nil? || db["version"].is_a?(String))
        end

        test "GET show runtime section has correct structure" do
          login_as_admin_api
          get api_v1_admin_system_info_path
          assert_response :success
          runtime = response.parsed_body["runtime"]

          assert runtime.key?("memory_mb")
          assert runtime.key?("uptime_seconds")
          assert runtime.key?("pool")

          assert(runtime["memory_mb"].nil? || runtime["memory_mb"].is_a?(Numeric))
        end

        test "GET show uptime_seconds is a non-negative integer" do
          login_as_admin_api
          get api_v1_admin_system_info_path
          assert_response :success
          uptime = response.parsed_body["runtime"]["uptime_seconds"]

          assert_kind_of Integer, uptime
          assert uptime >= 0
        end

        test "GET show pool contains exactly 5 keys without dead or checkout_timeout" do
          login_as_admin_api
          get api_v1_admin_system_info_path
          assert_response :success
          pool = response.parsed_body["runtime"]["pool"]

          assert_equal %w[busy connections idle size waiting], pool.keys.sort
          assert_not pool.key?("dead"), "pool must not include 'dead'"
          assert_not pool.key?("checkout_timeout"), "pool must not include 'checkout_timeout'"
        end

        test "GET show pool values are integers" do
          login_as_admin_api
          get api_v1_admin_system_info_path
          assert_response :success
          pool = response.parsed_body["runtime"]["pool"]

          %w[size connections busy idle waiting].each do |key|
            assert_kind_of Integer, pool[key], "pool.#{key} should be an Integer"
          end
        end

        test "GET show returns memory_mb nil when ps command fails" do
          login_as_admin_api
          SystemInfosController.any_instance.stubs(:memory_mb).returns(nil)
          get api_v1_admin_system_info_path
          assert_response :success
          assert_nil response.parsed_body["runtime"]["memory_mb"]
        end
      end
    end
  end
end
