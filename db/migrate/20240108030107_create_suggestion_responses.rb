class CreateSuggestionResponses < ActiveRecord::Migration[7.1]
  def change
    create_table :suggestion_responses do |t|
      t.references :suggestion_request, null: false, foreign_key: true
      t.text :raw_response
      t.integer :completion_tokens, null: false, default: 0
      t.integer :prompt_tokens, null: false, default: 0

      t.timestamps
    end
  end
end
