module Admin
  class LlmProvidersController < Admin::ApplicationController
    before_action :authorize_admin_read!, only: %i[index show]
    before_action :authorize_admin_write!, only: %i[edit update]
    before_action :set_llm_provider, only: %i[show edit update]

    def index
      @llm_providers = LlmProvider.includes(:llm_models).order(:name)
    end

    def show
      @llm_models = @llm_provider.llm_models.order(:name)
    end

    def edit; end

    def update
      params_to_update = llm_provider_params
      # Don't update API key if it's blank (keep existing key)
      params_to_update.delete(:api_key) if params_to_update[:api_key].blank?

      if @llm_provider.update(params_to_update)
        redirect_to admin_llm_provider_path(@llm_provider), notice: "LLM Provider was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

      def set_llm_provider
        @llm_provider = LlmProvider.find(params[:id])
      end

      def llm_provider_params
        params.expect(llm_provider: %i[api_endpoint api_key organization_id active])
      end
  end
end
