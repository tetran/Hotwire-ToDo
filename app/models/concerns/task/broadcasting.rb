class Task
  module Broadcasting
    extend ActiveSupport::Concern

    included do
      after_create_commit :broadcast_task_create, unless: :subtask?
      after_update_commit :broadcast_task_update, unless: :subtask?
      after_destroy_commit :broadcast_task_destroy, unless: :subtask?

      after_create_commit :broadcast_parent_on_subtask_create, if: :subtask?
      after_destroy_commit :broadcast_parent_update_on_destroy, if: :subtask?
      after_update_commit :broadcast_parent_on_subtask_update, if: -> { subtask? && saved_change_to_completed? }
    end

    private

      def broadcast_task_create
        broadcast_append_to project, target: "tasks", partial: "tasks/task", locals: { task: self }
      end

      def broadcast_task_update
        subtasks.load if parent? && !subtasks.loaded?
        broadcast_replace_to project, partial: "tasks/task", locals: { task: self }
      end

      def broadcast_task_destroy
        broadcast_remove_to project
      end

      def broadcast_parent_on_subtask_create
        reloaded = parent.reload.tap { |t| t.subtasks.load }
        reloaded.broadcast_replace_to(reloaded.project, partial: "tasks/task", locals: { task: reloaded })
      end

      def broadcast_parent_on_subtask_update
        parent.broadcast_replace_to(parent.project, partial: "tasks/task", locals: { task: parent })
      end

      def broadcast_parent_update_on_destroy
        return unless Task.exists?(parent_id)

        reloaded_parent = Task.find(parent_id)
        reloaded_parent.broadcast_replace_to(
          reloaded_parent.project,
          partial: "tasks/task",
          locals: { task: reloaded_parent },
        )
      end
  end
end
