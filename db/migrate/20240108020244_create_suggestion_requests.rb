class CreateSuggestionRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :suggestion_requests do |t|
      t.references :project, null: false, foreign_key: true
      t.references :requested_by, foreign_key: { to_table: :users }, null: false
      t.string :goal, null: false
      t.text :context
      t.date :start_date
      t.date :due_date
      t.text :raw_request

      t.timestamps
    end
  end
end
