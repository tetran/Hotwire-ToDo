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

      record_event if @success
      @task
    end

    def success?
      @success
    end

    private

      def create_with_series
        Task.transaction do
          series = build_series
          unless series.save
            merge_series_errors_into_task(series)
            raise ActiveRecord::Rollback
          end

          create_series_subtasks(series)
          @task.task_series = series
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
            # The seed task we're about to save is the first occurrence of
            # the series, so count it. Otherwise, a series with count=1
            # would still generate one extra follow-up task on completion.
            occurrences_generated: 1,
          ),
        )
        series.description = @task.description.to_s if @task.description.present?
        series
      end

      def create_series_subtasks(series)
        @recurrence.subtask_names.each_with_index do |name, index|
          series.series_subtasks.create!(name: name, position: index)
        end
      end

      def record_event
        Events::Recorder.record(
          event_name: "task_created",
          user: @user,
          project: @project,
          task: @task,
        )
      end

      def merge_series_errors_into_task(series)
        series.errors.each do |error|
          @task.errors.add(:base, error.full_message)
        end
      end
  end
end
