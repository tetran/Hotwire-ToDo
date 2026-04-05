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

        apply_recurrence_changes!
      rescue ActiveRecord::RecordInvalid => e
        merge_record_errors_into_task(e.record)
        raise ActiveRecord::Rollback
      end

      @task.errors.empty? && @task.persisted?
    end

    private

      def apply_recurrence_changes!
        if stop_series_requested?
          @task.task_series.stop!
        elsif start_series_requested?
          start_new_series!
        elsif apply_series_changes?
          apply_series_changes!
        end
      end

      def stop_series_requested?
        return false unless @task.task_series
        return false unless @recurrence.enabled_submitted?

        !@recurrence.enabled?
      end

      def start_series_requested?
        return false if @task.task_series

        @recurrence.enabled?
      end

      def start_new_series!
        series = TaskSeries.new(
          @recurrence.series_attrs.merge(
            project: @task.project,
            created_by: @task.created_by,
            assignee_id: @task.assignee_id,
            name: @task.name,
            # The task we're converting into a recurring task is itself the
            # first occurrence of the new series (mirrors Tasks::Creator).
            occurrences_generated: 1,
          ),
        )
        series.description = @task.description.to_s if @task.description.present?
        series.save!
        @task.update!(task_series: series)
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
