require "test_helper"

module Api
  module V1
    module Admin
      class EventsControllerTest < ActionDispatch::IntegrationTest
        # === Authentication & Authorization ===

        test "GET index returns 401 when not logged in" do
          get api_v1_admin_events_path
          assert_response :unauthorized
        end

        test "GET index returns 401 when logged in as regular user" do
          login_as(users(:regular_user))
          get api_v1_admin_events_path
          assert_response :unauthorized
        end

        test "GET index returns 403 when admin lacks EventLog read capability" do
          login_as_admin_api_read_only
          get api_v1_admin_events_path
          assert_response :forbidden
        end

        test "GET index returns 200 when admin has EventLog read capability" do
          login_as_admin_api
          get api_v1_admin_events_path
          assert_response :success
        end

        # === Response Structure ===

        test "GET index returns events array and meta" do
          login_as_admin_api
          get api_v1_admin_events_path
          assert_response :success

          json = response.parsed_body
          assert json.key?("events")
          assert json.key?("meta")
          assert_kind_of Array, json["events"]

          meta = json["meta"]
          assert meta.key?("page")
          assert meta.key?("per_page")
          assert meta.key?("total_count")
          assert meta.key?("total_pages")
        end

        test "GET index events contain expected fields" do
          login_as_admin_api
          get api_v1_admin_events_path
          assert_response :success

          event = response.parsed_body["events"].first
          assert event.key?("id")
          assert event.key?("event_name")
          assert event.key?("occurred_at")
          assert event.key?("feature_category")
          assert event.key?("metadata")
          assert event.key?("user")
          assert event["user"].key?("id")
          assert event["user"].key?("name")
        end

        test "GET index orders events by occurred_at desc" do
          login_as_admin_api
          get api_v1_admin_events_path
          assert_response :success

          events = response.parsed_body["events"]
          occurred_ats = events.pluck("occurred_at")
          assert_equal occurred_ats, occurred_ats.sort.reverse
        end

        # === Filters ===

        test "GET index filters by user_id" do
          login_as_admin_api
          user = users(:regular_user)
          get api_v1_admin_events_path, params: { user_id: user.id }
          assert_response :success

          events = response.parsed_body["events"]
          events.each do |event|
            assert_equal user.id, event["user"]["id"]
          end
        end

        test "GET index filters by project_id" do
          login_as_admin_api
          project = projects(:one)
          get api_v1_admin_events_path, params: { project_id: project.id }
          assert_response :success

          events = response.parsed_body["events"]
          events.each do |event|
            assert_equal project.id, event["project"]["id"]
          end
        end

        test "GET index filters by event_name" do
          login_as_admin_api
          get api_v1_admin_events_path, params: { event_name: "task_created" }
          assert_response :success

          events = response.parsed_body["events"]
          events.each do |event|
            assert_equal "task_created", event["event_name"]
          end
        end

        test "GET index filters by date range (from)" do
          login_as_admin_api
          from = 1.day.ago.iso8601
          get api_v1_admin_events_path, params: { from: from }
          assert_response :success

          events = response.parsed_body["events"]
          events.each do |event|
            assert Time.zone.parse(event["occurred_at"]) >= Time.zone.parse(from)
          end
        end

        test "GET index filters by date range (to)" do
          login_as_admin_api
          to_date = 2.days.ago.iso8601
          get api_v1_admin_events_path, params: { to: to_date }
          assert_response :success

          events = response.parsed_body["events"]
          events.each do |event|
            assert Time.zone.parse(event["occurred_at"]) <= Time.zone.parse(to_date)
          end
        end

        # === Pagination ===

        test "GET index paginates with default per_page" do
          login_as_admin_api
          get api_v1_admin_events_path
          assert_response :success

          meta = response.parsed_body["meta"]
          assert_equal 1, meta["page"]
          assert meta["per_page"].positive?
          assert meta["total_count"] >= 0
          assert meta["total_pages"] >= 0
        end

        test "GET index respects page parameter" do
          login_as_admin_api
          get api_v1_admin_events_path, params: { page: 2, per_page: 2 }
          assert_response :success

          meta = response.parsed_body["meta"]
          assert_equal 2, meta["page"]
          assert_equal 2, meta["per_page"]
        end

        test "GET index returns empty events for page beyond range" do
          login_as_admin_api
          get api_v1_admin_events_path, params: { page: 999 }
          assert_response :success

          events = response.parsed_body["events"]
          assert_empty events
        end
      end
    end
  end
end
