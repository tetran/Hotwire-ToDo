module ApplicationHelper
  def render_errors_for(model)
    render partial: "shared/form_errors", locals: { model: model } if model.errors.present?
  end

  def due_date_format(task)
    task.due_date.year == Time.current.year ? :short : :default
  end

  def user_icon(user)
    # ユーザーのアバターが更新されたときに反映させるため turbo_frame_tag を使用 (See users_controller#update)
    turbo_frame_tag "", class: "user-avatar-#{user.id}" do
      if user.avatar.attached?
        image_tag url_for(user.avatar.variant(:icon)), class: "user-avatar"
      else
        tag.span user.user_name[0], class: "user-avatar user-initial-sign"
      end
    end
  end

  def debug_block(&block)
    return unless Rails.env.development?

    raw "<div class='debug-block'>#{capture(&block)}</div>"
  end
end
