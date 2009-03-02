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
    @min_published_at = nil
    @max_published_at = nil
    @memes.each { |meme| 
      meme.distinct_meme_items.each { |mi|
        item = mi.item_relationship.item
        @items.push(item)
        @max_published_at = item.published_at if !@max_published_at || @max_published_at < item.published_at
        @min_published_at = item.published_at if !@min_published_at || @min_published_at > item.published_at
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
