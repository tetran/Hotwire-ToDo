module Tasks
  class Creator
    attr_reader :task

    def initialize(project:, user:, task_params:, recurrence_params:)
      @project = project
      @user = user
      @task_params = task_params
      @recurrence = RecurrenceParamsNormalizer.new(recurrence_params)
      @success = false
    end

    def call
      @task = @project.tasks.build(@task_params.merge(created_by: @user))

      if @recurrence.enabled?
        create_with_series
      else
        @success = @task.save
      end

      @task
    end

    def success?
      @success
    end

    private

      def create_with_series
        Task.transaction do
          @task.task_series = build_series
          raise ActiveRecord::Rollback unless @task.save

          @success = true
        end
      end

      def build_series
        series = TaskSeries.new(
          @recurrence.series_attrs.merge(
            project: @project,
            created_by: @user,
            assignee_id: @task.assignee_id,
            name: @task.name,
          ),
        )
        series.description = @task.description.to_s if @task.description.present?
        series.save!
        create_series_subtasks(series)
        series
      end

      def create_series_subtasks(series)
        @recurrence.subtask_names.each_with_index do |name, index|
          series.series_subtasks.create!(name: name, position: index)
        end
      end
  end
end
