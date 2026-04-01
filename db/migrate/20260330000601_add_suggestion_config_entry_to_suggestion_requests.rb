class AddSuggestionConfigEntryToSuggestionRequests < ActiveRecord::Migration[8.1]
  def change
    add_reference :suggestion_requests, :suggestion_config_entry, null: true, foreign_key: true
    change_column_null :suggestion_requests, :llm_model_id, true
  end
end
