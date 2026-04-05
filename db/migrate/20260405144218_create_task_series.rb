class CreateTaskSeries < ActiveRecord::Migration[8.1]
  def change
    create_table :task_series do |t|
      t.references :project, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :assignee, null: true, foreign_key: { to_table: :users }
      t.string :name, null: false, limit: 100
      t.integer :frequency, null: false
      t.integer :interval, null: false, default: 1
      t.string :by_weekday
      t.integer :end_mode, null: false, default: 0
      t.integer :count
      t.integer :occurrences_generated, null: false, default: 0
      t.date :until_date
      t.string :rrule, null: false
      t.datetime :stopped_at

      t.timestamps
    end

    add_index :task_series, :stopped_at
  end
end
