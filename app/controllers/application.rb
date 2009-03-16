# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all
  helper_method :current_user_session, :current_user
  filter_parameter_logging :password, :password_confirmation
  
  layout "layouts/pretty_layout_7_with_container"

  before_filter :load_flight
  def load_flight 
    if params[:flight].nil?
      @flight = Flight.find(:first, 
                            :conditions => ["controller_name = ? and action_name = ?", controller_name, action_name], 
      :order => "id desc"
      )
    else
      @flight = Flight.find(params[:flight])
    end
    if @flight.nil?
      @flight = Flight.find(:first, 
        :conditions => ["controller_name = ? and action_name = ?", "site", "index"], 
        :order => "id desc"
      )
    end
  end
  
  private
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end
    
    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end
    
    def require_user
      unless current_user
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to login_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access this page"
        redirect_to account_url
        return false
      end
    end
    
    def store_location
      session[:return_to] = request.request_uri
    end
    
    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end
end
