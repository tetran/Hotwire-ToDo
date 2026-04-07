module Tasks
  class InlineFieldsController < ApplicationController
    include TaskDependent

    EDITABLE_FIELDS = %w[name description due_date].freeze

    before_action :set_field

    def edit; end

    # NOTE: Bypasses Tasks::Updater intentionally. Recurrence template
    # sync is out of scope for inline edits (behaves like scope=only_this).
    def update
      respond_to do |format|
        if @task.update(field_params)
          format.turbo_stream
          format.html { redirect_to task_url(@task) }
        else
          format.turbo_stream { render :edit, formats: [:html], status: :unprocessable_content }
          format.html { render :edit, status: :unprocessable_content }
        end
      end
    end

    private

      def set_field
        @field = params[:id]
        head :not_found unless EDITABLE_FIELDS.include?(@field)
      end

      def field_params
        params.expect(task: [@field.to_sym])
      end
  end
end
