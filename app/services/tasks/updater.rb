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
      return false if @recurrence.enabled_submitted? && !@recurrence.enabled?

      @recurrence.template_changed?(@task.task_series)
    end

    def call
      Task.transaction do
        raise ActiveRecord::Rollback unless @task.update(@task_params)

        if stop_series_requested?
          @task.task_series.stop!
        elsif apply_series_changes?
          apply_series_changes!
        end
      rescue ActiveRecord::RecordInvalid => e
        merge_record_errors_into_task(e.record)
        raise ActiveRecord::Rollback
      end

      @task.errors.empty? && @task.persisted?
    end

    private

      def stop_series_requested?
        return false unless @task.task_series
        return false unless @recurrence.enabled_submitted?

        !@recurrence.enabled?
      end

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

      def merge_record_errors_into_task(record)
        return if record == @task

        record.errors.each do |error|
          @task.errors.add(:base, error.full_message)
        end
      end
  end
end
