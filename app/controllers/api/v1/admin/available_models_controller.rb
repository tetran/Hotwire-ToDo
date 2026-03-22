module Api
  module V1
    module Admin
      class AvailableModelsController < ApplicationController
        before_action -> { require_capability!("LlmProvider", "write") }
        before_action :set_llm_provider

        def index
          models = ModelListService.fetch_models(
            @llm_provider.name,
            @llm_provider.api_key,
            organization_id: @llm_provider.organization_id,
          )
          render json: models
        rescue LlmClient::ApiError => e
          render json: { error: e.message }, status: :bad_gateway
        end

        private

          def set_llm_provider
            @llm_provider = LlmProvider.find(params[:llm_provider_id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Not found" }, status: :not_found
          end
      end
    end
  end
end
