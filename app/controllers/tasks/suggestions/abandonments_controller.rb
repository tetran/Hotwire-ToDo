module Tasks
  module Suggestions
    class AbandonmentsController < ApplicationController
      def create
        session = SuggestionSession
                  .where(requested_by: current_user)
                  .find_by(id: params[:suggestion_id])
        return head :no_content unless session

        response = SuggestionResponse
                   .joins(suggestion_request: :suggestion_session)
                   .where(suggestion_sessions: { id: session.id })
                   .find_by(id: params[:suggestion_response_id])
        SuggestionOutcomeService.record_abandonment(suggestion_response: response) if response

        head :no_content
      end
    end
  end
end
