module SessionsHelper
  def sign_in(user)
    session[:user_id] = user.id
  end

  def require_login
    return if current_user.present?

    redirect_to login_path
  end

  def current_user
    return if session[:user_id].blank?

    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def require_logout
    redirect_to project_url(current_user.inbox_project.id) if current_user.present?
  end
end
