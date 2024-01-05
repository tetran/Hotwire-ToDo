class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.date :due_date, null: false
      t.boolean :completed, null: false, default: false
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :assignee, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
