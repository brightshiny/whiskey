class RunsController < ApplicationController

  before_filter :require_user, :except => :show

  def index
    @runs = Run.find(:all)
  end
  
  def show
    @run = Run.find(params[:id])
    @memes = Meme.find(:all, :conditions => ["run_id = ?", @run.id], :include => [ :meme_items ])
    @items = []
    @memes.each { |meme| 
      meme.items.each { |item|
        @items.push(item)
      }
    }
    # @items = @items.sort_by{ |i| i.title.size }
    @items = @items.sort_by{ |i| i.item_relationships.map{ |ir| ir.cosine_similarity }.sum }
  end
  
end
