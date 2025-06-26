class Admin::LlmProvidersController < Admin::ApplicationController
  before_action :authorize_admin_read!, only: [:index, :show]
  before_action :authorize_admin_write!, only: [:new, :create, :edit, :update]
  before_action :authorize_admin_delete!, only: [:destroy]
  before_action :set_llm_provider, only: [:show, :edit, :update, :destroy]

  def index
    @llm_providers = LlmProvider.includes(:llm_models).order(:name)
  end

  def show
    @llm_models = @llm_provider.llm_models.order(:name)
  end

  def new
    @llm_provider = LlmProvider.new
  end

  def create
    @llm_provider = LlmProvider.new(llm_provider_params)

    if @llm_provider.save
      redirect_to admin_llm_provider_path(@llm_provider), notice: 'LLM Provider was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    params_to_update = llm_provider_params
    # Don't update API key if it's blank (keep existing key)
    params_to_update.delete(:api_key) if params_to_update[:api_key].blank?
    
    if @llm_provider.update(params_to_update)
      redirect_to admin_llm_provider_path(@llm_provider), notice: 'LLM Provider was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @llm_provider.llm_models.joins(:suggestion_requests).exists?
      redirect_to admin_llm_providers_path, alert: 'Cannot delete provider that has models being used by suggestion requests.'
      return
    end

    @llm_provider.destroy
    redirect_to admin_llm_providers_path, notice: 'LLM Provider was successfully deleted.'
  end

  private

  def set_llm_provider
    @llm_provider = LlmProvider.find(params[:id])
  end

  def llm_provider_params
    params.require(:llm_provider).permit(:name, :api_endpoint, :api_key, :organization_id, :active)
  end
end
