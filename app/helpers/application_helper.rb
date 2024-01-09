module ApplicationHelper
  def render_errors_for(model)
    render partial: "shared/form_errors", locals: { model: model } if model.errors.present?
  end

  def due_date_format(task)
    task.due_date.year == Time.current.year ? :short : :default
  end

  def user_icon(user)
    turbo_frame_tag "", class: "user-avatar-#{user.id}" do
      if user.avatar.attached?
        image_tag user.avatar, class: "user-avatar"
      else
        tag.span user.user_name[0], class: "user-avatar user-initial-sign"
      end
    end
  end
end
