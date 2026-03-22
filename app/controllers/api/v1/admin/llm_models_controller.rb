module Api
  module V1
    module Admin
      class LlmModelsController < ApplicationController
        before_action :set_llm_provider
        before_action :set_llm_model, only: %i[show update destroy]
        before_action -> { require_capability!("LlmProvider", "read") }, only: %i[index show]
        before_action -> { require_capability!("LlmProvider", "write") }, only: %i[create update]
        before_action -> { require_capability!("LlmProvider", "delete") }, only: %i[destroy]

        def index
          models = @llm_provider.llm_models.order(:id)
          render json: models.as_json
        end

        def show
          render json: @llm_model.as_json
        end

        def create
          model = @llm_provider.llm_models.build(llm_model_params)
          if model.save
            render json: model.as_json, status: :created
          else
            render json: { errors: model.errors }, status: :unprocessable_entity
          end
        end

        def update
          if @llm_model.update(llm_model_params)
            render json: @llm_model.as_json
          else
            render json: { errors: @llm_model.errors }, status: :unprocessable_entity
          end
        end

        def destroy
          @llm_model.destroy
          head :no_content
        end

        private

          def set_llm_provider
            @llm_provider = LlmProvider.find(params[:llm_provider_id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Not found" }, status: :not_found
          end

          def set_llm_model
            @llm_model = @llm_provider.llm_models.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Not found" }, status: :not_found
          end

          def llm_model_params
            params.expect(llm_model: %i[name display_name active default_model])
          end
      end
    end
  end
end
