require "test_helper"

module Api
  module V1
    module Admin
      class RateLimitingTest < ActionDispatch::IntegrationTest
        setup do
          Rack::Attack.enabled = true
          Rack::Attack.reset!
        end

        teardown do
          Rack::Attack.enabled = false
        end

        test "同一 IP から 5 回失敗後は 429 を返す" do
          5.times do
            post api_v1_admin_session_path,
                 params: { email: "wrong@example.com", password: "wrong" },
                 as: :json,
                 headers: { "REMOTE_ADDR" => "1.2.3.4" }
            assert_response :unauthorized
          end

          post api_v1_admin_session_path,
               params: { email: "wrong@example.com", password: "wrong" },
               as: :json,
               headers: { "REMOTE_ADDR" => "1.2.3.4" }
          assert_response :too_many_requests
        end

        test "異なる IP から同一 email で 5 回失敗後は 429 を返す" do
          5.times do |i|
            post api_v1_admin_session_path,
                 params: { email: "target@example.com", password: "wrong" },
                 as: :json,
                 headers: { "REMOTE_ADDR" => "1.2.3.#{i + 10}" }
            assert_response :unauthorized
          end

          post api_v1_admin_session_path,
               params: { email: "target@example.com", password: "wrong" },
               as: :json,
               headers: { "REMOTE_ADDR" => "1.2.3.99" }
          assert_response :too_many_requests
        end

        test "throttle レスポンスに JSON error メッセージが含まれる" do
          6.times do
            post api_v1_admin_session_path,
                 params: { email: "flood@example.com", password: "wrong" },
                 as: :json,
                 headers: { "REMOTE_ADDR" => "9.9.9.9" }
          end
          assert_response :too_many_requests
          assert_equal "Too many requests", response.parsed_body["error"]
        end

        test "throttle レスポンスに Retry-After ヘッダーが含まれる" do
          6.times do
            post api_v1_admin_session_path,
                 params: { email: "retry@example.com", password: "wrong" },
                 as: :json,
                 headers: { "REMOTE_ADDR" => "8.8.8.8" }
          end
          assert_response :too_many_requests
          assert response.headers["Retry-After"].present?, "Retry-After ヘッダーが存在すること"
          assert_match(/\A\d+\z/, response.headers["Retry-After"], "Retry-After は秒数の整数文字列であること")
        end
      end
    end
  end
end
