module ApplicationHelper
  def render_errors_for(model)
    render partial: "shared/form_errors", locals: { model: model } if model.errors.present?
  end

  def due_date_format(task)
    task.due_date.year == Time.current.year ? :short : :default
  end

  def user_icon(user, viewer: nil)
    display_user_avatar(user, viewer: viewer)
  end

  def debug_block(&)
    return unless Rails.env.development?

    content_tag(:div, capture(&), class: "debug-block")
  end
end
