class RunsController < ApplicationController

  # before_filter :require_user, :except => :show

  def all
    @items = User.find(5).recent_documents_from_feeds(2000)
  end

  def index
    @runs = Run.paginate(
      :page => params[:page], 
      :include => :memes, 
      :per_page => 30,
      :order => "id desc"
    )
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
  
  def view
    @run = Run.find(params[:id])
    @memes = Meme.find(:all, 
      :conditions => ["run_id = ?", @run.id], 
      :include => [ :meme_items => :item_relationship ]).sort_by{ |m| m.strength }.reverse.reject{ |m| m.items.size <= 2 }
  end
  
end
