class AddTaskSeriesIdToTasks < ActiveRecord::Migration[8.1]
  def change
    add_reference :tasks, :task_series, null: true, foreign_key: true, index: true
    add_index :tasks, :task_series_id,
              unique: true,
              where: "completed = FALSE",
              name: "index_tasks_on_pending_task_series_id"
  end
end
