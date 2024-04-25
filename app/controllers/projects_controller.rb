class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update]
  rescue_from ActiveRecord::RecordNotFound, with: :redirect_to_inbox

  def index
    redirect_to_inbox
  end

  def show
    @new_task = @project.tasks.build
    if params[:c].present?
      @tasks = @project.tasks.where(id: params[:t]) if params[:t].present?
      return
    end

    session[:current_project_id] = @project.id
    @tasks = @project.tasks.uncompleted.with_rich_text_description_and_embeds.order(:created_at)

    # Inboxを最初に表示するため`dedicated`の降順でソート
    @projects = current_user.participating_projects
    # ログインユーザーを最初に表示
    @members = @project.members_with_priority(current_user)
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params.merge(owner: current_user, dedicated: false))

    respond_to do |format|
      if @project.save
        format.html { redirect_to project_url(@project), success: "Project was successfully created." }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @project.errors, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("modal", partial: "projects/form", locals: { project: @project }), status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @project.update(project_params)
        format.html do
          redirect_to project_url(session[:current_project_id] || @project.id), success: "Project was successfully updated."
        end
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @project.errors, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("modal", partial: "projects/form", locals: { project: @project }), status: :unprocessable_entity }
      end
    end
  end

  private

    def set_project
      @project = current_user.projects.unarchived.find(params[:id])
    end

    def project_params
      params.require(:project).permit(:name, :archived)
    end

    def redirect_to_inbox
      redirect_to project_url(current_user.inbox_project.id)
    end
end
