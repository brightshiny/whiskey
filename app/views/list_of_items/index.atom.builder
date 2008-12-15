atom_feed do |feed|
  feed.title("Have a shot of Whiskey!!!")
  feed.updated(@items.first.created_at)
  
  @items.each do |item|
    feed.entry(item, :url=>item.link, :published=>item.published_at) do |entry|
      entry.title(item.feed.title + ': ' + item.title)
      entry.content(item.content, :type => 'html')
      entry.author { |author| author.name(item.author) }
    end
  end
end
