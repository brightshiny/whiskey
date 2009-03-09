atom_feed do |feed|
  feed.title("refinr")
  feed.updated(@items.first.created_at) unless @items.nil? || @items.size <= 0
  @items.each do |item|
    feed.entry(item, :url=>item.link, :published=>item.published_at) do |entry|
      entry.title(item.feed.title + ': ' + (item.title || "") )
      entry.content(item.content, :type => 'html') if !item.content.nil?
      entry.author { |author| author.name(item.author) } if !item.author.nil?
    end
  end
end
