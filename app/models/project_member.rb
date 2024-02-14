class ProjectMember < ApplicationRecord
  belongs_to :project
  belongs_to :user

  after_destroy :unassign_tasks

  private

    def unassign_tasks
      project.tasks.where(assignee: user).update_all(assignee_id: nil)
    end
end
