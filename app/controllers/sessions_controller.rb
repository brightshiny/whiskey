# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  
  # render new.rhtml
  def new
  end

  def create
    if using_open_id?
      open_id_authentication(params[:openid_url])
    else
      password_authentication(params[:login], params[:password])
    end
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end
  
  protected
  
  def open_id_authentication(openid_url)
    authenticate_with_open_id(openid_url, :required => [:nickname, :email]) do |result, identity_url, registration|
      if result.successful?
        @user = User.find_or_initialize_by_identity_url(identity_url)
        if @user.new_record?
          @user.login = registration['nickname']
          @user.email = registration['email']
          @user.save(false)
        end
        self.current_user = @user
        successful_login
      else
        failed_login result.message
      end
    end
  end
  
  def password_authentication(login, password)
    self.current_user = User.authenticate(login, password)
    if logged_in?
      successful_login
    else
      failed_login
    end
  end
  
  def failed_login(message = "Authentication failed.")
    flash.now[:error] = message
    render :action => 'new'
  end
  
  def successful_login
    if params[:remember_me] == "1"
      self.current_user.remember_me
      cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
    end
    redirect_back_or_default('/')
    flash[:notice] = "Logged in successfully"
  end

#   # Be sure to include AuthenticationSystem in Application Controller instead
#   include AuthenticatedSystem
# 
#   # render new.rhtml
#   def new
#   end
# 
#   def create
#     logout_keeping_session!
#     user = User.authenticate(params[:login], params[:password])
#     if user
#       # Protects against session fixation attacks, causes request forgery
#       # protection if user resubmits an earlier form using back
#       # button. Uncomment if you understand the tradeoffs.
#       # reset_session
#       self.current_user = user
#       new_cookie_flag = (params[:remember_me] == "1")
#       handle_remember_cookie! new_cookie_flag
#       redirect_back_or_default('/')
#       flash[:notice] = "Logged in successfully"
#     else
#       note_failed_signin
#       @login       = params[:login]
#       @remember_me = params[:remember_me]
#       render :action => 'new'
#     end
#   end
# 
#   def destroy
#     logout_killing_session!
#     flash[:notice] = "You have been logged out."
#     redirect_back_or_default('/')
#   end
# 
# protected
#   # Track failed login attempts
#   def note_failed_signin
#     flash[:error] = "Couldn't log you in as '#{params[:login]}'"
#     logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
#   end
end
