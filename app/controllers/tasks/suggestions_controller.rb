module Tasks
  # タスクの提案を行う
  class SuggestionsController < ApplicationController
    def create
      @suggestion_request = SuggestionRequest.new(suggestion_request_params.merge(requested_by: current_user))
      set_view_variables

      unless @suggestion_request.save
        render "tasks/new", status: :unprocessable_content
        return
      end

      SuggestionResponse.batch_create(@suggestion_request, send_chat_request)

      render turbo_stream: turbo_stream.replace("task_suggestion", partial: "tasks/suggestions")
    end

    private

      def suggestion_request_params
        params.expect(suggestion_request: %i[goal context due_date start_date project_id])
      end

      def set_view_variables
        @task = @suggestion_request.project.tasks.build
        @show_suggestion = true
      end

      def send_chat_request
        ActiveSupport::Notifications.instrument "chat.openai", request_id: @suggestion_request.id do
          OpenAI::Client.new.chat(parameters: @suggestion_request.openai_params)
        end
      end
  end
end
