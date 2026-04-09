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
    creator = Tasks::Creator.new(
      project: @project,
      user: current_user,
      task_params: task_params,
      recurrence_params: recurrence_params,
    )
    @task = creator.call

    respond_to do |format|
      if creator.success?
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
    updater = Tasks::Updater.new(
      task: @task,
      task_params: task_params,
      recurrence_params: recurrence_params,
      scope: scope_param,
      user: current_user,
    )

    if updater.template_change_blocked?
      flash.now[:error] = t("controllers.tasks.update.template_change_requires_all_future")
      render :edit, status: :unprocessable_content
    else
      respond_update(updater)
    end
  end

  # DELETE /tasks/1
  def destroy
    project = @task.project
    @task.destroy!
    Events::Recorder.record(
      event_name: "task_deleted",
      user: current_user,
      project: project,
    )

    respond_to do |format|
      format.html { redirect_to tasks_url, success: t("controllers.tasks.destroy.success") }
      format.turbo_stream
    end
  end

  private

    def set_task
      @task = current_user.tasks.find(params[:id])
    end

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

    def recurrence_params
      rp = params[:recurrence] || params.dig(:task, :recurrence)
      return nil unless rp.is_a?(ActionController::Parameters) || rp.is_a?(Hash)

      rp = ActionController::Parameters.new(rp) if rp.is_a?(Hash)
      rp.permit(:frequency, :interval, :end_mode, :count, :until_date,
                by_weekday: [], subtask_names: [])
    end

    def scope_param
      params[:scope].presence_in(%w[only_this all_future]) || "only_this"
    end

    def respond_update(updater)
      respond_to do |format|
        if updater.call
          format.html { redirect_to task_url(@task), success: t("controllers.tasks.update.success") }
          format.turbo_stream
        else
          format.html { render :edit, status: :unprocessable_content }
        end
      end
    end
end
