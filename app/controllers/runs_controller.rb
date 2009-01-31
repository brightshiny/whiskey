class RunsController < ApplicationController
  
  def index
    @runs = Run.find(:all)
  end
  
  def show
    @run = Run.find(params[:id])
    @memes = Meme.find(:all, :conditions => ["run_id = ?", @run.id], :include => [ :meme_items ])
  end
  
end
