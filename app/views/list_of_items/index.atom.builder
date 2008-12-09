atom_feed do |feed|
  feed.title("Your Whiskey feed!")
  feed.updated(@posts.first.created_at
  
  @posts.each do |post|
    feed.entry(post) do |entry|
      entry.title(post.title)
      entry.content(post.body, :type => 'html')
      entry.author { |author| author.name("Depends :)") }
    end
  end
end
