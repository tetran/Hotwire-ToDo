module Tasks
  class AssignsController < ApplicationController
    include TaskDependent

    def create
      @task.assign!(params[:assignee_id])
      respond_to do |format|
        format.turbo_stream
      end
    end

    def destroy
      @task.unassign!
      respond_to do |format|
        format.turbo_stream
      end
    end
  end
end
