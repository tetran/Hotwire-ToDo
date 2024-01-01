json.extract! task, :id, :user_id, :name, :due_date, :completed, :created_at, :updated_at
json.url task_url(task, format: :json)
