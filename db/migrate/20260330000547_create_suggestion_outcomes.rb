class CreateSuggestionOutcomes < ActiveRecord::Migration[8.1]
  def change
    create_table :suggestion_outcomes do |t|
      t.references :suggestion_response, null: false, foreign_key: true, index: { unique: true }
      t.integer :total_suggested, null: false, default: 0
      t.integer :total_adopted, null: false, default: 0
      t.decimal :acceptance_rate, precision: 5, scale: 2, null: false, default: 0
      t.boolean :high_acceptance, null: false, default: false

      t.timestamps
    end
  end
end
