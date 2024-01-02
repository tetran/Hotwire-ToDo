module Tasks
  class CompletesController < ApplicationController
    def create
      @task = Task.find(params[:task_id])
      @task.complete!
      respond_to do |format|
        format.turbo_stream
      end
    end

    def destroy
      @task = Task.find(params[:task_id])
      @task.uncomplete!
      respond_to do |format|
        format.turbo_stream
      end
    end
  end
end
