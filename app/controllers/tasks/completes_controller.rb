module Tasks
  class CompletesController < ApplicationController
    include ProjectDependent
    include TaskDependent

    before_action :set_project, only: :index
    before_action :set_task, only: %i[create]

    def index
      return unless params[:show]

      @completed_tasks = @project
                         .tasks.root_tasks.completed
                         .includes(:subtasks, :task_series)
                         .with_rich_text_description_and_embeds
                         .order(updated_at: :desc)
    end

    def create
      @task.complete!(completed_by: current_user)
      Events::Recorder.record(
        event_name: "task_completed",
        user: current_user,
        project: @task.project,
        task: @task,
      )
      respond_to do |format|
        format.turbo_stream
      end
    end
  end
end
