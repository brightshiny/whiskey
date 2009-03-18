function should_page_be_updated(responseText) {
  if($('#version_loaded')[0].value != responseText) {
    if($('#updater')[0]) {
      var ih = "<div class=\"grid_12\"> <h3>refinr has updated</h3> <p><a href=\"/\">Refresh now to get the new edition</a> or wait <span id=\"seconds_until_refresh\"><span id=\"seconds_left\">30</span> seconds</span> and we'll reload the page for you.</p> </div> ";
      $('#updater')[0].innerHTML = ih;
      $('#updater').fadeIn("slow");
      $.timer(1000, function (timer) {
        var newTime = parseInt($('#seconds_left')[0].innerHTML) - 1;
        if(newTime <= 0) {
          newTime = 0;
          timer.stop();
        }
        $('#seconds_left')[0].innerHTML = newTime;
      });
      $.timer(30000, function (timer) {
        location.href='/';
      });
    }
  }
}

function update_time() {
  if($('#time_ago')) {
    time_span = $('#time_ago')[0];
    time_span_content = time_span.innerHTML;
    time_pieces = time_span_content.split(/ /);
    time = parseInt(time_pieces[0]);
    units = time_pieces[1];
    var newTime = "";
    if((units == "minute")&&(time == 1)) {
      time += 1;
      newTime = time + " minutes";
    } else if(time_span_content.split(/ /).length > 2) {
      time = 1;
      newTime += "1 minute";
    } else {
      if(units == "minutes") {
        time += 1; 
        newTime = [time, units].join(" "); 
      } 
    }
    time_span.innerHTML = newTime;
  }
}

function track_click(src, link_name) {
	if(document.images) {
		(new Image()).src = src;
	}
	if (pageTracker) {
		pageTracker._trackPageview(link_name)
	}
}

function autolink(text) {
  array_of_text = text.split(/\s/);
  for(var i=0;i<array_of_text.length;i++) {
    word = array_of_text[i];
    if(word.match(/^(http|https)\:\/\//)) {
      word = '<a class="in_tweet_link" href="' + word + '">' + word + '</a>';
      array_of_text[i] = word;
    } else if(word.match(/^\@/)) {
      word = '<a class="reply_tweet" href="http://twitter.com/' + word.replace(/\@/,'') + '">' + word + '</a>';
      array_of_text[i] = word;
    }
  }
  return array_of_text.join(" ");
}



