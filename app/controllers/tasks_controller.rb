class TasksController < ApplicationController
  before_action :set_task, only: %i[show edit update destroy]
  before_action :set_project, only: %i[new create]

  # GET /tasks/1
  def show
    @comments = @task.comments.includes(:user).order(:created_at)
    @subtasks = @task.subtasks.includes(:assignee).with_rich_text_description_and_embeds.order(:created_at)
  end

  # GET /tasks/new
  def new
    @task = @project.tasks.build
    set_suggestion_variables
  end

  # GET /tasks/1/edit
  def edit; end

  # POST /tasks
  def create
    @task = @project.tasks.build(task_params.merge(created_by: current_user))

    respond_to do |format|
      if @task.save
        format.html { redirect_to task_url(@task), success: t("controllers.tasks.create.success") }
        format.turbo_stream
      else
        set_suggestion_variables
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /tasks/1
  def update
    respond_to do |format|
      if @task.update(task_params)
        format.html { redirect_to task_url(@task), success: t("controllers.tasks.update.success") }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  # DELETE /tasks/1
  def destroy
    @task.destroy!

    respond_to do |format|
      format.html { redirect_to tasks_url, success: t("controllers.tasks.destroy.success") }
      format.turbo_stream
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_task
      @task = current_user.tasks.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def task_params
      params.expect(task: %i[name due_date description assignee])
    end

    def set_project
      @project = current_user.projects.find(params[:project_id])
    end

    def set_suggestion_variables
      @suggestion_session = SuggestionSession.new(
        project: @project,
        requested_by: current_user,
        start_date: Time.zone.today,
        due_date: Time.zone.today + 3.months,
      )
      @show_suggestion = false
    end
end
