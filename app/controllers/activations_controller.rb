class ActivationsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  
  def new
    @user_session = UserSession.new
    @user = User.find(:first, :conditions => ["perishable_token = ?", params[:perishable_token]])
    cookies[:u] = { :value => params[:activation_code] }
    raise Exception if @user.active?
  end

  def create
    @user_session = UserSession.new
    @user = User.find(:first, :conditions => ["perishable_token = ?", params[:perishable_token]])

    raise Exception if @user.active?

    if @user.activate!(params)
      @user.deliver_activation_confirmation!
      flash[:notice] = "Your account has been activated."
      redirect_to account_url
      cookies[:u] = { :value => "", :expires => (Time.now - 999) }
    else
      render :action => :new
    end
  end

end