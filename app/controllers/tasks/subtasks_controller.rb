module Tasks
  class SubtasksController < ApplicationController
    include TaskDependent

    before_action :reject_completed_parent

    def new
      @subtask = @task.subtasks.build(project: @task.project, created_by: current_user)
    end

    def create
      @subtask = build_subtask
      respond_to do |format|
        if @subtask.save
          @task.subtasks.reload
          format.turbo_stream
          format.html { redirect_to task_path(@task) }
        else
          format.turbo_stream { render :new, status: :unprocessable_content }
          format.html { render :new, status: :unprocessable_content }
        end
      end
    end

    private

      def build_subtask
        @task.subtasks.build(
          subtask_params.merge(project_id: @task.project_id, created_by: current_user),
        )
      end

      def subtask_params
        params.expect(task: %i[name due_date description])
      end

      def reject_completed_parent
        head :unprocessable_entity if @task.completed?
      end
  end
end
