module UsersHelper
  # Pre-Fork skeleton. Phase 1B-β (Rails) implements per the contract below;
  # the view-side migration of `comment.user.user_name`, `member.user_name`, and
  # `user_icon` to these helpers is owned by the same phase.

  # Returns the display name to render for `user` in the context of `viewer`.
  # - admin viewer (or admin SPA context) → user.user_name (raw)
  # - non-admin viewer, deactivated user  → first 2 chars + "**"
  # - non-admin viewer, active user       → user.user_name
  def display_user_name(user, viewer:)
    raise NotImplementedError, "Phase 1B will implement display_user_name"
  end

  # Returns avatar markup for `user` in the context of `viewer`.
  # Deactivated users render a person_off SVG with a slate background.
  def display_user_avatar(user, viewer:)
    raise NotImplementedError, "Phase 1B will implement display_user_avatar"
  end

  # Returns a neutral slate "退会済み" pill for deactivated users; nil otherwise.
  def deactivation_status_badge(user)
    raise NotImplementedError, "Phase 1B will implement deactivation_status_badge"
  end
end
