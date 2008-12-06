# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  include AuthenticatedSystem

  layout "layouts/default"
  
  before_filter :make_sure_user_has_nickname
  def make_sure_user_has_nickname
    if logged_in? && current_user.nickname.nil?
      logger.info "User must have nickname"
      redirect_to edit_user_path(current_user.token) and return false
    end
  end

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '2630008fbadc4918832b7a79353ef974'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password

end
