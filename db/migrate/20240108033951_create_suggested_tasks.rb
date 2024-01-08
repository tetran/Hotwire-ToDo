class CreateSuggestedTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :suggested_tasks do |t|
      t.references :suggestion_response, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.date :due_date

      t.timestamps
    end
  end
end
