class UsersController < ApplicationController

  skip_before_filter :make_sure_user_has_nickname, :only => [ :edit, :update ]
  before_filter :login_required, :except => [ :new, :create ]
  
  def index
    redirect_to :action => "show", :id => current_user.nickname and return false
  end
  
  def show
  end
 
  def new
    @user = User.new
  end
 
  def create
    logout_keeping_session!
    @user = User.new(params[:user])
    success = @user && @user.save
    if success && @user.errors.empty?
      # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset session
      self.current_user = @user # !! now logged in
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end
  
  def edit
  end
  
  def update
    respond_to do |format|
      if current_user.update_attributes(params[:user])
        flash[:notice] = 'Bar was successfully updated.'
        format.html { redirect_to(user_path(current_user.nickname)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => current_user.errors, :status => :unprocessable_entity }
      end
    end
  end
  
end
