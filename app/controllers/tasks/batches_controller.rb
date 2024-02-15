module Tasks
  # タスクを一括で作成する
  class BatchesController < ApplicationController
    include ProjectDependent

    def create
      @tasks = Task.create_from_suggestion(tasks_params, @project.id, current_user)
      @new_task = @project.tasks.build
      respond_to do |format|
        format.turbo_stream
      end
    end

    private

      def tasks_params
        params[:tasks].select { |_, task| task[:checked] == '1' }
      end
  end
end
