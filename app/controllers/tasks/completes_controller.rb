module Tasks
  class CompletesController < ApplicationController
    include TaskDependent

    def create
      @task.complete!
      respond_to do |format|
        format.turbo_stream
      end
    end

    def destroy
      @task.uncomplete!
      respond_to do |format|
        format.turbo_stream
      end
    end
  end
end
