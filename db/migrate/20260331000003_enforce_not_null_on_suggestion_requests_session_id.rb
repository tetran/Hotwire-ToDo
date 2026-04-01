class EnforceNotNullOnSuggestionRequestsSessionId < ActiveRecord::Migration[8.0]
  def up
    change_column_null :suggestion_requests, :suggestion_session_id, false
  end

  def down
    change_column_null :suggestion_requests, :suggestion_session_id, true
  end
end
