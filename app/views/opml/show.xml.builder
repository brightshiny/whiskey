xml.instruct! :xml, :version => "1.0"
xml.opml(:version => "1.0") do |opml|
  opml.head do |head|
    head.title('refinr Feeds, OPML Style')
  end
  opml.body do |body|
    for feed in @feeds do
      body.outline(:text => "Whiskey - #{feed.title}", :title => "Whiskey - #{feed.title}", 
        :xmlUrl => url_for(:controller => :list_of_items, :action => :index, :only_path => false,
          :f => feed.encrypted_id, :u => @user.encrypted_id))
    end
  end
end