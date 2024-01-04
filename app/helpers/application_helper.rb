module ApplicationHelper
  def render_errors_for(model)
    render partial: "shared/form_errors", locals: { model: model } if model.errors.present?
  end
end
