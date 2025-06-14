class Admin::DashboardController < Admin::ApplicationController
  def index
    @stats = {
      users_count: User.count,
      projects_count: Project.count,
      tasks_count: Task.count,
      active_tasks_count: Task.uncompleted.count,
      recent_users: User.order(created_at: :desc).limit(5),
      recent_projects: Project.order(created_at: :desc).limit(5)
    }
  end
end