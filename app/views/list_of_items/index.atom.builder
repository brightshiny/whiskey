atom_feed do |feed|
  feed.title("Have a shot of Whiskey!!!")
  feed.updated(@items.first.created_at) unless @items.nil?
  @items.each do |item|
    feed.entry(item, :url=>item.link, :published=>item.published_at) do |entry|
      entry.title(item.feed.title + ': ' + item.display_non_nil_title)
      entry.content(item.display_non_nil_content, :type => 'html')
      entry.author { |author| author.name(item.display_non_nil_author) }
    end
  end
end
