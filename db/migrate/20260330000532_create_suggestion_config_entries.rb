class CreateSuggestionConfigEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :suggestion_config_entries do |t|
      t.references :suggestion_config, null: false, foreign_key: true
      t.references :llm_model, null: false, foreign_key: true
      t.references :prompt_set, null: false, foreign_key: true
      t.integer :weight, null: false

      t.timestamps
    end

    add_index :suggestion_config_entries,
              %i[suggestion_config_id llm_model_id prompt_set_id],
              unique: true,
              name: "idx_suggestion_config_entries_unique_combo"
  end
end
