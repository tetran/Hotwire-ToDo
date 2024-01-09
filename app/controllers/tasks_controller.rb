class TasksController < ApplicationController
  before_action :set_task, only: %i[ show edit update destroy ]
  before_action :set_project, only: %i[ new create ]

  # GET /tasks or /tasks.json
  def index
    @tasks = current_user.tasks.with_rich_text_description_and_embeds.order(:created_at)
    @new_task = current_user.inbox_project.tasks.build
  end

  # GET /tasks/1 or /tasks/1.json
  def show
    @comments = @task.comments.includes(:user).order(:created_at)
  end

  # GET /tasks/new
  def new
    @task = @project.tasks.build
    set_suggestino_variables
  end

  # GET /tasks/1/edit
  def edit
  end

  # POST /tasks or /tasks.json
  def create
    @task = @project.tasks.build(task_params.merge(created_by: current_user))

    respond_to do |format|
      if @task.save
        @new_task = @task.project.tasks.build
        @members = @project.members.sort { |lhs, _| lhs == current_user ? -1 : 1 }

        format.html { redirect_to task_url(@task), success: "Task was successfully created." }
        format.json { render :show, status: :created, location: @task }
        format.turbo_stream
      else
        set_suggestino_variables
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tasks/1 or /tasks/1.json
  def update
    respond_to do |format|
      if @task.update(task_params)
        @members = @task.project.members.sort { |lhs, _| lhs == current_user ? -1 : 1 }

        format.html { redirect_to task_url(@task), success: "Task was successfully updated." }
        format.json { render :show, status: :ok, location: @task }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tasks/1 or /tasks/1.json
  def destroy
    @task.destroy!

    respond_to do |format|
      format.html { redirect_to tasks_url, success: "Task was successfully destroyed." }
      format.json { head :no_content }
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
      params.require(:task).permit(:name, :due_date, :description, :assignee)
    end

    def set_project
      @project = current_user.projects.find(params[:project_id])
    end

    def set_suggestino_variables
      @suggestion_request = SuggestionRequest.new(
        project: @project,
        requested_by: current_user,
        start_date: Time.zone.today,
        due_date: Time.zone.today + 3.months
      )
      @show_suggestion = false
    end
end
