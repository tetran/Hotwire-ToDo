class Admin::AvailableModelsController < Admin::ApplicationController
  before_action :set_llm_provider
  
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def index
    if @llm_provider.api_key.blank?
      render json: { error: "API key not configured for this provider" }, status: :unprocessable_content
      return
    end

    models = ModelListService.fetch_models(
      @llm_provider.name,
      @llm_provider.api_key,
      organization_id: @llm_provider.organization_id
    )

    render json: { models: models }
  end

  private

  def set_llm_provider
    @llm_provider = LlmProvider.find(params[:llm_provider_id])
  end
  
  def record_not_found
    render json: { error: "Provider not found" }, status: :not_found
  end
end
