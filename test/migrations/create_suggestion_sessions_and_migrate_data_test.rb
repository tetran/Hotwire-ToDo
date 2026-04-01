require "test_helper"
require Rails.root.join("db/migrate/20260331000001_create_suggestion_sessions_and_migrate_data")

class CreateSuggestionSessionsAndMigrateDataTest < ActiveSupport::TestCase
  LEGACY_REQUEST_COLUMNS = %i[goal context start_date due_date project_id requested_by_id].freeze

  setup do
    skip_unless_explicit_migration_test_target!
    @migration = CreateSuggestionSessionsAndMigrateData.new
    prepare_pre_migration_schema!
  end

  teardown do
    restore_latest_schema_state!
  end

  test "up migrates legacy rows and enforces suggestion_session_id not null" do
    @migration.up

    assert connection.table_exists?(:suggestion_sessions)
    assert connection.column_exists?(:suggestion_requests, :suggestion_session_id)
    assert_equal false, connection.columns(:suggestion_requests).find { it.name == "suggestion_session_id" }.null
    assert_equal 1, connection.select_value("SELECT COUNT(*) FROM suggestion_sessions").to_i

    migrated_session_id = connection.select_value("SELECT suggestion_session_id FROM suggestion_requests LIMIT 1")
    assert migrated_session_id.present?
    assert_equal 0, null_session_reference_count
  end

  test "down restores legacy columns and removes suggestion_sessions" do
    @migration.up
    @migration.down

    assert_equal false, connection.table_exists?(:suggestion_sessions)
    assert_equal false, connection.column_exists?(:suggestion_requests, :suggestion_session_id)
    assert connection.column_exists?(:suggestion_requests, :goal)
    assert connection.column_exists?(:suggestion_requests, :context)
    assert connection.column_exists?(:suggestion_requests, :start_date)
    assert connection.column_exists?(:suggestion_requests, :due_date)
    assert connection.column_exists?(:suggestion_requests, :project_id)
    assert connection.column_exists?(:suggestion_requests, :requested_by_id)
  end

  private

    def connection
      ActiveRecord::Base.connection
    end

    def prepare_pre_migration_schema!
      clear_suggestion_data!
      drop_sessions_table_if_present!
      remove_session_reference_if_present!
      add_legacy_columns_if_missing!
      insert_legacy_request_row
    end

    def clear_suggestion_data!
      connection.execute("DELETE FROM suggested_tasks") if connection.table_exists?(:suggested_tasks)
      connection.execute("DELETE FROM suggestion_outcomes") if connection.table_exists?(:suggestion_outcomes)
      connection.execute("DELETE FROM suggestion_responses") if connection.table_exists?(:suggestion_responses)
      connection.execute("DELETE FROM suggestion_requests") if connection.table_exists?(:suggestion_requests)
    end

    def drop_sessions_table_if_present!
      return unless connection.table_exists?(:suggestion_sessions)

      connection.drop_table :suggestion_sessions
    end

    def remove_session_reference_if_present!
      remove_fk_if_exists(:suggestion_requests, :suggestion_sessions)
      connection.remove_index :suggestion_requests, :suggestion_session_id if connection.index_exists?(
        :suggestion_requests, :suggestion_session_id
      )
      connection.remove_column :suggestion_requests, :suggestion_session_id if connection.column_exists?(
        :suggestion_requests, :suggestion_session_id
      )
    end

    def add_legacy_columns_if_missing!
      add_column_if_missing(:suggestion_requests, :goal, :string)
      add_column_if_missing(:suggestion_requests, :context, :text)
      add_column_if_missing(:suggestion_requests, :start_date, :date)
      add_column_if_missing(:suggestion_requests, :due_date, :date)
      add_column_if_missing(:suggestion_requests, :project_id, :bigint)
      add_column_if_missing(:suggestion_requests, :requested_by_id, :bigint)

      connection.add_index :suggestion_requests, :project_id unless connection.index_exists?(:suggestion_requests,
                                                                                             :project_id)
      connection.add_index :suggestion_requests, :requested_by_id unless connection.index_exists?(:suggestion_requests,
                                                                                                  :requested_by_id)
      add_fk_if_missing(:suggestion_requests, :projects, :project_id)
      add_fk_if_missing(:suggestion_requests, :users, :requested_by_id)
    end

    def insert_legacy_request_row
      quoted = quoted_legacy_request_attributes

      connection.execute(<<~SQL.squish)
        INSERT INTO suggestion_requests
          (llm_model_id, goal, context, start_date, due_date, project_id, requested_by_id, created_at, updated_at)
        VALUES
          (#{quoted[:llm_model_id]}, #{quoted[:goal]}, #{quoted[:context]}, #{quoted[:start_date]}, #{quoted[:due_date]}, #{quoted[:project_id]}, #{quoted[:requested_by_id]}, #{quoted[:created_at]}, #{quoted[:updated_at]})
      SQL
    end

    def restore_latest_schema_state!
      @migration.up unless latest_schema_state?
      connection.change_column_null :suggestion_requests, :suggestion_session_id, false
    end

    def latest_schema_state?
      connection.table_exists?(:suggestion_sessions) &&
        connection.column_exists?(:suggestion_requests, :suggestion_session_id) &&
        LEGACY_REQUEST_COLUMNS.none? { |column| connection.column_exists?(:suggestion_requests, column) }
    end

    def null_session_reference_count
      connection.select_value(
        "SELECT COUNT(*) FROM suggestion_requests WHERE suggestion_session_id IS NULL",
      ).to_i
    end

    def quoted_legacy_request_attributes
      legacy_request_attributes.transform_values { |value| connection.quote(value) }
    end

    def legacy_request_attributes
      now = Time.zone.parse("2026-03-31 12:00:00")
      {
        llm_model_id: llm_models(:gpt_turbo).id,
        goal: "Legacy goal",
        context: "Legacy context",
        start_date: Date.new(2026, 4, 1),
        due_date: Date.new(2026, 4, 10),
        project_id: projects(:one).id,
        requested_by_id: users(:regular_user).id,
        created_at: now,
        updated_at: now,
      }
    end

    def add_column_if_missing(table_name, column_name, type)
      return if connection.column_exists?(table_name, column_name)

      connection.add_column table_name, column_name, type
    end

    def add_fk_if_missing(from_table, to_table, column)
      return if connection.foreign_keys(from_table).any? do |fk|
        fk.to_table == to_table.to_s && fk.options[:column].to_s == column.to_s
      end

      connection.add_foreign_key from_table, to_table, column: column
    end

    def remove_fk_if_exists(from_table, to_table)
      fk = connection.foreign_keys(from_table).find { |candidate| candidate.to_table == to_table.to_s }
      return unless fk

      connection.remove_foreign_key from_table, to_table
    end

    def skip_unless_explicit_migration_test_target!
      return if explicit_migration_test_target?
      return if ENV["RUN_MIGRATION_TESTS"] == "1"

      skip "Migration tests run only when explicitly targeted."
    end

    def explicit_migration_test_target?
      ARGV.grep_v(/\A-/).any? { |arg| arg.include?("test/migrations") }
    end
end
