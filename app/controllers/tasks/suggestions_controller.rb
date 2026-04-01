module Tasks
  # タスクの提案を行う
  class SuggestionsController < ApplicationController
    def create
      @suggestion_session = build_suggestion_session
      set_view_variables

      return render_new_task unless @suggestion_session.save

      entry = SuggestionRoutingService.select_entry
      return render_suggestion_error("suggestions.no_config") unless entry

      result = call_llm(entry)
      return render_suggestion_error("suggestions.llm_error") unless result

      last_request = @suggestion_session.suggestion_requests.last
      SuggestionResponse.batch_create(last_request, result)

      render_suggestions
    end

    private

      def build_suggestion_session
        @project = current_user.projects.find(suggestion_session_params[:project_id])
        SuggestionSession.new(
          suggestion_session_params.except(:project_id).merge(
            requested_by: current_user,
            project: @project,
          ),
        )
      end

      def suggestion_session_params
        params.expect(suggestion_session: %i[goal context due_date start_date project_id])
      end

      def call_llm(entry)
        service = SuggestionLlmService.new(entry: entry, session: @suggestion_session,
                                           variables: suggestion_variables)
        service.call
      end

      def suggestion_variables
        {
          goal: @suggestion_session.goal,
          context: @suggestion_session.context.to_s,
          start_date: @suggestion_session.start_date.to_s,
          due_date: @suggestion_session.due_date.to_s,
        }
      end

      def render_new_task
        render "tasks/new", status: :unprocessable_content
      end

      def render_suggestion_error(key)
        @error_message = I18n.t(key)
        set_view_variables
        render turbo_stream: turbo_stream.replace(
          "form2",
          partial: "tasks/ask_ai",
        )
      end

      def render_suggestions
        render turbo_stream: turbo_stream.replace("task_suggestion", partial: "tasks/suggestions")
      end

      def set_view_variables
        @task = @suggestion_session.project.tasks.build if @suggestion_session.project
        @show_suggestion = true
      end
  end
end
