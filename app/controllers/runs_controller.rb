class RunsController < ApplicationController
  
  def index
    @runs = Run.find(:all)
  end
  
  def show
    @run = Run.find(params[:id], :include => [ :memes => :item_relationships ])
  end
  
end
