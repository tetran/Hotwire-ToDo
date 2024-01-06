module Tasks
  class AssignsController < ApplicationController
    def create
      task = current_user.tasks.find(params[:task_id])
      assignee = task.project.members.find(params[:assignee_id])
      task.update!(assignee: assignee)

      redirect_to task.project
    end

    def destroy
      task = current_user.tasks.find(params[:task_id])
      task.update!(assignee_id: nil)

      redirect_to task.project
    end
  end
end
