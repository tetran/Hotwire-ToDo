class TaskSeriesSubtask < ApplicationRecord
  belongs_to :task_series, inverse_of: :series_subtasks

  validates :name, presence: true, length: { maximum: 100 }
end
