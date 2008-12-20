function buildPage() {
  window.item_on_left = -1;
  $.each( window.feed, function(index, item) {
    html = '<div class="item" id="item_' + index + '"><div class="sleeve"><div class="heading"><a target="_blank" class="title" href=""></a></div><div class="feed"><span class="author"></span><a class="feed_name" href="" target="_blank"></a></div><div class="published_at"></div><div class="description"></div></div></div>';
    $("#slider").append(html);
    $("#item_" + index + " a.title").append(document.createTextNode(item.title));
    $("#item_" + index + " a.title").attr({"href" : item.link});
    $("#item_" + index + " .feed a.feed_name").append(document.createTextNode(item.feed_name));
    $("#item_" + index + " .feed a.feed_name").attr({"href" : item.feed_link });
    $("#item_" + index + " .author").append(document.createTextNode(item.author));
    if((item.author) && (item.author.length > 0) && (item.author != "null")) {
      $("#item_" + index + " .author").append(" &middot; ");
    }
    $("#item_" + index + " .published_at").append(document.createTextNode(item.published_at));
    $("#item_" + index + " .description").append(document.createTextNode(unescape(item.description)));
  });
}

function getCurrentSliderLeftPosition() {
  var current_slider_left_position = $("#slider").position().left;
  return current_slider_left_position;
}

function getItemWidth() {
  var item_width = $(".item").width();
  return item_width;
}

function determineMaxLength() {
  var maximum_length = window.feed.length * getItemWidth();
  return maximum_length;
}

function determinePositionToScrollTo(direction) {
  var item_width = getItemWidth();
  var current_slider_left_position = getCurrentSliderLeftPosition();
  var position_to_scroll_to = current_slider_left_position + direction * item_width;
  while(position_to_scroll_to % item_width != 0) {
    position_to_scroll_to -= 1;
  }
  if((current_slider_left_position >= 0)&&(direction > 0)) {
    position_to_scroll_to = 0;
  } 
  return position_to_scroll_to;
}

function enableKeyPresses() {
  window.acceptKeyPress = true;
}

function disableKeyPresses() {
  window.acceptKeyPress = false;
}

function addTrackingPixel() {
  i = new Image();
  i.src = "/reads/create?u=" + window.encrypted_user_id + "&i=" + window.feed[window.item_on_left].id;
  $("body").append(i);
}

function doReadTracking() {
  clearTimeout(window.readClock);
  window.readClock = setTimeout("addTrackingPixel()",3000);
}

function updateActiveItem(direction) {
  window.item_on_left += (1*direction);
  if(window.item_on_left < 0) {
    window.item_on_left = 0;
  } else if(window.item_on_left > window.feed.length) {
    window.item_on_left = window.feed.length;
  }
}

function highlightActiveItem() {
  $(".item div.sleeve").removeClass("active");
  $("#item_" + window.item_on_left + " div.sleeve").addClass("active");
}

function nextItemExists() {
  if(window.item_on_left < window.feed.length) {
    return true;
  } else {
    return false;
  }
}

function previousItemExists() {
  if(window.item_on_left > 0) {
    return true;
  } else {
    return false;
  }
}

function doAnimation(position_to_scroll_to) {    
  $("#slider").animate({left:position_to_scroll_to}, {duration: 700, easing: "easeInOutExpo", complete: enableKeyPresses});
  if(getCurrentSliderLeftPosition() != position_to_scroll_to) {
    $("#slider").animate({left:position_to_scroll_to});
  }
}

function scrollNext() {  
  if(nextItemExists()) { 
    disableKeyPresses();
    updateActiveItem(1);
    highlightActiveItem();
    doAnimation(determinePositionToScrollTo(-1));
    doReadTracking();
  }
}

function scrollPrevious() {
  if(previousItemExists()) { 
    disableKeyPresses();
    updateActiveItem(-1);
    highlightActiveItem();
    doAnimation(determinePositionToScrollTo(1));
    doReadTracking();
  }
}

function openLinkInNewWindow() {
  var destination = $("#item_" + window.item_on_left + " a.title").attr('href');
  window.open(destination);
  return false;
}
