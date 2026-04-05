module Tasks
  class Updater
    def initialize(task:, task_params:, recurrence_params:, scope:)
      @task = task
      @task_params = task_params
      @recurrence = RecurrenceParamsNormalizer.new(recurrence_params)
      @scope = scope
    end

    def template_change_blocked?
      return false unless @task.task_series
      return false if @scope == "all_future"
      return false if @recurrence.blank?

      @recurrence.template_changed?(@task.task_series)
    end

    def call
      return false unless @task.update(@task_params)
      return true unless apply_series_changes?

      Task.transaction { apply_series_changes! }
      true
    end

    private

      def apply_series_changes?
        @scope == "all_future" && @task.task_series
      end

      def apply_series_changes!
        series = @task.task_series
        series.sync_from_task!(@task)
        apply_template_updates!(series)
        series.propagate_to_pending!(except: @task)
      end

      def apply_template_updates!(series)
        return if @recurrence.blank?

        attrs = @recurrence.template_update_attrs
        series.update!(attrs) if attrs.any?
      end
  end
end
