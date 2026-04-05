module Tasks
  class RecurrencesController < ApplicationController
    include TaskDependent

    def destroy
      @task.task_series&.stop!
      respond_to do |format|
        format.turbo_stream
      end
    end
  end
end
