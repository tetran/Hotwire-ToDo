module ApplicationHelper
  def user_name
    current_user.name || current_user.email.split('@').first
  end
end
