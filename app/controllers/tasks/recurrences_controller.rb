module Tasks
  class RecurrencesController < ApplicationController
    include TaskDependent

    def destroy
      return head :unprocessable_content if @task.task_series.nil?

      @task.task_series.stop!
      respond_to do |format|
        format.turbo_stream
      end
    end
  end
end
