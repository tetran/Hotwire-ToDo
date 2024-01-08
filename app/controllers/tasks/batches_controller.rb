module Tasks
  # タスクを一括で作成する
  class BatchesController < ApplicationController
    def create
      tasks = Task.create_from_suggestion(tasks_params, params[:project_id], current_user)
      redirect_to project_path(params[:project_id]), success: "#{tasks.length} tasks were created successfully."
    end

    private

      def tasks_params
        params[:tasks].select { |_, task| task[:checked] == '1' }
      end
  end
end
