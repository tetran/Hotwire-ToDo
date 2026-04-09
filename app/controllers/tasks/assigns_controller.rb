module Tasks
  class AssignsController < ApplicationController
    include TaskDependent

    def create
      old_assignee_id = @task.assignee_id
      @task.assign!(params[:assignee_id])
      record_assignee_changed(old_assignee_id, @task.assignee_id)
      respond_to do |format|
        format.turbo_stream
      end
    end

    def destroy
      old_assignee_id = @task.assignee_id
      @task.unassign!
      record_assignee_changed(old_assignee_id, nil)
      respond_to do |format|
        format.turbo_stream
      end
    end

    private

      def record_assignee_changed(old_id, new_id)
        Events::Recorder.record(
          event_name: "assignee_changed",
          user: current_user,
          project: @task.project,
          task: @task,
          metadata: { old_assignee_id: old_id, new_assignee_id: new_id },
        )
      end
  end
end
