module Tasks
  class AssignsController < ApplicationController
    include TaskDependent

    def create
      assignee = @task.project.members.find(params[:assignee_id])
      task.update!(assignee: assignee)

      redirect_to @task.project
    end

    def destroy
      @task.update!(assignee_id: nil)

      redirect_to @task.project
    end
  end
end
