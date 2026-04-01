class CreateSuggestionSessionsAndMigrateData < ActiveRecord::Migration[8.0]
  def up
    create_table :suggestion_sessions do |t|
      t.integer :source_request_id, null: false
      t.string :goal, null: false
      t.text :context
      t.date :start_date
      t.date :due_date
      t.references :project, null: false, foreign_key: true
      t.references :requested_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :suggestion_sessions, :source_request_id, unique: true

    add_reference :suggestion_requests, :suggestion_session, foreign_key: true

    execute <<~SQL
      INSERT INTO suggestion_sessions (
        source_request_id,
        goal,
        context,
        start_date,
        due_date,
        project_id,
        requested_by_id,
        created_at,
        updated_at
      )
      SELECT
        id,
        goal,
        context,
        start_date,
        due_date,
        project_id,
        requested_by_id,
        created_at,
        updated_at
      FROM suggestion_requests
    SQL

    execute <<~SQL
      UPDATE suggestion_requests
      SET suggestion_session_id = (
        SELECT suggestion_sessions.id
        FROM suggestion_sessions
        WHERE suggestion_sessions.source_request_id = suggestion_requests.id
        LIMIT 1
      )
    SQL

    ensure_no_unmapped_suggestion_requests!

    remove_column :suggestion_requests, :goal
    remove_column :suggestion_requests, :context
    remove_column :suggestion_requests, :start_date
    remove_column :suggestion_requests, :due_date
    remove_reference :suggestion_requests, :project, foreign_key: true
    remove_reference :suggestion_requests, :requested_by, foreign_key: { to_table: :users }
    remove_column :suggestion_sessions, :source_request_id
    change_column_null :suggestion_requests, :suggestion_session_id, false
  end

  def down
    add_reference :suggestion_requests, :project, foreign_key: true
    add_reference :suggestion_requests, :requested_by, foreign_key: { to_table: :users }
    add_column :suggestion_requests, :goal, :string
    add_column :suggestion_requests, :context, :text
    add_column :suggestion_requests, :start_date, :date
    add_column :suggestion_requests, :due_date, :date

    execute <<~SQL
      UPDATE suggestion_requests
      SET goal = (SELECT goal FROM suggestion_sessions WHERE suggestion_sessions.id = suggestion_requests.suggestion_session_id),
          context = (SELECT context FROM suggestion_sessions WHERE suggestion_sessions.id = suggestion_requests.suggestion_session_id),
          start_date = (SELECT start_date FROM suggestion_sessions WHERE suggestion_sessions.id = suggestion_requests.suggestion_session_id),
          due_date = (SELECT due_date FROM suggestion_sessions WHERE suggestion_sessions.id = suggestion_requests.suggestion_session_id),
          project_id = (SELECT project_id FROM suggestion_sessions WHERE suggestion_sessions.id = suggestion_requests.suggestion_session_id),
          requested_by_id = (SELECT requested_by_id FROM suggestion_sessions WHERE suggestion_sessions.id = suggestion_requests.suggestion_session_id)
      WHERE suggestion_session_id IS NOT NULL
    SQL

    ensure_no_missing_legacy_required_values!
    change_column_null :suggestion_requests, :goal, false
    change_column_null :suggestion_requests, :project_id, false
    change_column_null :suggestion_requests, :requested_by_id, false

    remove_reference :suggestion_requests, :suggestion_session, foreign_key: true
    drop_table :suggestion_sessions
  end

  private

    def ensure_no_unmapped_suggestion_requests!
      unmapped_count = select_value(<<~SQL).to_i
        SELECT COUNT(*)
        FROM suggestion_requests
        WHERE suggestion_session_id IS NULL
      SQL
      return if unmapped_count.zero?

      raise ActiveRecord::MigrationError,
            "Data migration failed: #{unmapped_count} suggestion_requests were not mapped to suggestion_sessions"
    end

    def ensure_no_missing_legacy_required_values!
      missing_count = select_value(<<~SQL).to_i
        SELECT COUNT(*)
        FROM suggestion_requests
        WHERE goal IS NULL
           OR project_id IS NULL
           OR requested_by_id IS NULL
      SQL
      return if missing_count.zero?

      raise ActiveRecord::MigrationError,
            "Down migration failed: #{missing_count} suggestion_requests are missing required legacy values"
    end
end
