class CreateTaskSeriesSubtasks < ActiveRecord::Migration[8.1]
  def change
    create_table :task_series_subtasks do |t|
      t.references :task_series, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false, limit: 100
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
