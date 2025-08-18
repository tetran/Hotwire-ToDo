module Tasks
  class CompletesController < ApplicationController
    include ProjectDependent
    include TaskDependent

    before_action :set_project, only: :index
    before_action :set_task, only: %i[create]

    def index
      return unless params[:show]

      @completed_tasks = @project.tasks.completed.with_rich_text_description_and_embeds.order(updated_at: :desc)
    end

    def create
      @task.complete!
      respond_to do |format|
        format.turbo_stream
      end
    end
  end
end
