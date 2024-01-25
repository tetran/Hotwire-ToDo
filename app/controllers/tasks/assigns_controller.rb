module Tasks
  class AssignsController < ApplicationController
    include TaskDependent

    def create
      @task.assign!(params[:assignee_id])
      redirect_to @task.project
    end

    def destroy
      @task.unassign!
      redirect_to @task.project
    end
  end
end
