module ApplicationHelper
  def render_errors_for(model)
    render partial: "shared/form_errors", locals: { model: model } if model.errors.present?
  end

  def due_date_format(task)
    task.due_date.year == Time.current.year ? :short : :default
  end
end
