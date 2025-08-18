module Admin
  class LlmModelsController < Admin::ApplicationController
    before_action :authorize_admin_read!, only: %i[index show]
    before_action :authorize_admin_write!, only: %i[new create edit update]
    before_action :authorize_admin_delete!, only: [:destroy]
    before_action :set_llm_provider
    before_action :set_llm_model, only: %i[show edit update destroy]

    def index
      @llm_models = @llm_provider.llm_models.order(:name)
    end

    def show; end

    def new
      @llm_model = @llm_provider.llm_models.build
    end

    def edit; end

    def create
      @llm_model = @llm_provider.llm_models.build(llm_model_params)

      if @llm_model.save
        redirect_to admin_llm_provider_llm_model_path(@llm_provider, @llm_model),
                    notice: "LLM Model was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @llm_model.update(llm_model_params)
        redirect_to admin_llm_provider_llm_model_path(@llm_provider, @llm_model),
                    notice: "LLM Model was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @llm_model.suggestion_requests.exists?
        redirect_to admin_llm_provider_path(@llm_provider),
                    alert: "Cannot delete model that is being used by suggestion requests."
        return
      end

      @llm_model.destroy
      redirect_to admin_llm_provider_path(@llm_provider),
                  notice: "LLM Model was successfully deleted."
    end

    private

      def set_llm_provider
        @llm_provider = LlmProvider.find(params[:llm_provider_id])
      end

      def set_llm_model
        @llm_model = @llm_provider.llm_models.find(params[:id])
      end

      def llm_model_params
        params.expect(llm_model: %i[name display_name active default_model])
      end
  end
end
