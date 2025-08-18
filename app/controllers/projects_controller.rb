class ProjectsController < ApplicationController
  before_action :set_project, only: %i[show edit update]
  rescue_from ActiveRecord::RecordNotFound, with: :redirect_to_inbox

  def index
    redirect_to_inbox
  end

  def show
    session[:current_project_id] = @project.id

    # タスク追加・編集フォームでの「キャンセル」を効率化するための分岐
    if params[:c]
      @tasks = @project.tasks.where(id: params[:t]) if params[:t]
      return
    end

    @tasks = @project.uncompleted_tasks

    # ログインユーザーを最初に表示
    @members = @project.members_with_priority(current_user)
  end

  def new
    @project = Project.new
  end

  def edit; end

  def create
    @project = Project.new(project_params.merge(owner: current_user, dedicated: false))

    respond_to do |format|
      if @project.save
        format.html { redirect_to project_url(@project), success: "Project was successfully created." }
      else
        format.html { render :new, status: :unprocessable_content }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("modal", partial: "projects/form", locals: { project: @project }),
                 status: :unprocessable_content
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @project.update(project_params)
        format.html do
          redirect_to project_url(session[:current_project_id] || @project.id),
                      success: "Project was successfully updated."
        end
      else
        format.html { render :edit, status: :unprocessable_content }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("modal", partial: "projects/form", locals: { project: @project }),
                 status: :unprocessable_content
        end
      end
    end
  end

  private

    def set_project
      @project = current_user.projects.unarchived.find(params[:id])
    end

    def project_params
      params.expect(project: %i[name archived])
    end

    def redirect_to_inbox
      redirect_to project_url(current_user.inbox_project.id)
    end
end
