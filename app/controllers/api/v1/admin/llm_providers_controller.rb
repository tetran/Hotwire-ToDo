module Api
  module V1
    module Admin
      class LlmProvidersController < ApplicationController
        before_action :set_llm_provider, only: %i[show update]
        before_action -> { require_capability!("LlmProvider", "read") }, only: %i[index show]
        before_action -> { require_capability!("LlmProvider", "write") }, only: %i[update]

        def index
          providers = LlmProvider.order(:id)
          render json: providers.as_json(except: :api_key_encrypted)
        end

        def show
          render json: @llm_provider.as_json(except: :api_key_encrypted)
        end

        def update
          if @llm_provider.update(llm_provider_params)
            render json: @llm_provider.as_json(except: :api_key_encrypted)
          else
            render json: { errors: @llm_provider.errors }, status: :unprocessable_entity
          end
        end

        private

          def set_llm_provider
            @llm_provider = LlmProvider.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Not found" }, status: :not_found
          end

          def llm_provider_params
            params.expect(llm_provider: %i[name api_endpoint organization_id active api_key])
          end
      end
    end
  end
end
