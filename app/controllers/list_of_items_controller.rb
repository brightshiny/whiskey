class ListOfItemsController < ApplicationController

  def default
    # generate feed
    # display feed
    @posts = Array.new
    respond_to do |format|
      format.atom
    end
  end
end
