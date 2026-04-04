module Tasks
  # タスクを一括で作成する
  class BatchesController < ApplicationController
    include ProjectDependent

    def create
      create_tasks
      record_adoption
      respond_to do |format|
        format.turbo_stream
      end
    end

    private

      def create_tasks
        if params[:suggestion_session_id].present? && tasks_params.present?
          Task.transaction do
            @parent_task = create_parent_task
            @tasks = Task.create_subtasks_from_suggestion(tasks_params, @parent_task)
          end
        elsif params[:suggestion_session_id].blank?
          @tasks = Task.create_from_suggestion(tasks_params, @project.id, current_user)
        else
          @tasks = []
        end
      end

      def tasks_params
        @tasks_params ||= params[:tasks].select { |_, task| task[:checked] == "1" }
      end

      def create_parent_task
        session = SuggestionSession
                  .where(requested_by: current_user, project_id: @project.id)
                  .find(params[:suggestion_session_id])
        Task.create!(
          name: session.goal.truncate(100),
          project_id: @project.id,
          created_by: current_user,
        )
      end

      def record_adoption
        return if params[:suggestion_response_id].blank?

        response = SuggestionResponse
                   .joins(suggestion_request: :suggestion_session)
                   .where(suggestion_sessions: { requested_by_id: current_user.id, project_id: @project.id })
                   .find_by(id: params[:suggestion_response_id])
        return unless response

        SuggestionOutcomeService.record_adoption(
          suggestion_response: response,
          adopted_count: @tasks&.count || 0,
        )
      end
  end
end
