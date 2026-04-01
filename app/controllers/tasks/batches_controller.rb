module Tasks
  # タスクを一括で作成する
  class BatchesController < ApplicationController
    include ProjectDependent

    def create
      @tasks = Task.create_from_suggestion(tasks_params, @project.id, current_user)
      record_adoption
      respond_to do |format|
        format.turbo_stream
      end
    end

    private

      def tasks_params
        params[:tasks].select { |_, task| task[:checked] == "1" }
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
          adopted_count: @tasks.count,
        )
      end
  end
end
