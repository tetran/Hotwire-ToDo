module UsersHelper
  # Returns the display name to render for `user` in the context of `viewer`.
  # - admin viewer → user.user_name (raw)
  # - non-admin viewer, deactivated user → first 2 chars + "**"
  # - non-admin viewer, active user → user.user_name
  def display_user_name(user, viewer:)
    return user.user_name if viewer&.admin?
    return "#{user.user_name[0..1]}**" if user.deactivated?

    user.user_name
  end

  # Returns avatar markup for `user` in the context of `viewer`.
  # Deactivated users render a person_off icon with a slate background,
  # regardless of viewer role (visual redaction signal).
  # Active users render the standard avatar (turbo_frame + image or initial).
  def display_user_avatar(user, viewer: nil) # rubocop:disable Lint/UnusedMethodArgument
    if user.deactivated?
      content_tag(:span, class: "user-avatar user-avatar--deactivated") do
        content_tag(:span, "person_off", class: "material-symbols-outlined")
      end
    else
      turbo_frame_tag "", class: "user-avatar-#{user.id}" do
        if user.avatar.attached?
          image_tag url_for(user.avatar.variant(:icon)), class: "user-avatar"
        else
          tag.span user.user_name[0], class: "user-avatar user-initial-sign"
        end
      end
    end
  end

  # Returns a neutral slate "退会済み" pill for deactivated users; nil otherwise.
  def deactivation_status_badge(user)
    return nil unless user.deactivated?

    content_tag(:span, class: "deactivation-badge") do
      concat content_tag(:span, "person_off", class: "material-symbols-outlined")
      concat " 退会済み"
    end
  end
end
