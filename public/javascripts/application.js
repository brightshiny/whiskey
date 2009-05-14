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
    if(newTime != "") {
      time_span.innerHTML = newTime;
    }
  }
}

function track_click(src, title) {
	if(document.images) {
		(new Image()).src = src;
	}
	if (pageTracker) {
		try { pageTracker._trackPageview("/link/to/" + title); } catch(err) {}
	}
}

function autolink(text) {
  array_of_text = text.split(/\s/);
  for(var i=0;i<array_of_text.length;i++) {
    word = array_of_text[i];
    if(word.match(/^(http|https)\:\/\//)) {
      if(word.length > 50) {
        word = '<a class="in_tweet_link" href="' + word + '" title="' + word + '">' + word.substring(0,25) + '...</a>';
      } else {
        word = '<a class="in_tweet_link" href="' + word + '">' + word + '</a>';
      }
      array_of_text[i] = word;
    } else if(word.match(/^\@/)) {
      word = '<a class="reply_tweet" href="http://twitter.com/' + word.replace(/\@/,'') + '">' + word + '</a>';
      array_of_text[i] = word;
    }
  }
  return array_of_text.join(" ");
}


function display_tweet(result, prepend, quickly) {
  var tweet_id_no_hash = "tweet_"+result.id;
  var tweet_id = "#" + tweet_id_no_hash;
  if(prepend) {
    $('<div></div>').html("").attr('id',tweet_id_no_hash).addClass("tweet").prependTo("#topical_tweets").hide();
  } else {
    $('<div></div>').html("").attr('id',tweet_id_no_hash).addClass("tweet").appendTo("#topical_tweets").hide();
  }
  $('<div></div>').html("").attr('id',tweet_id_no_hash+"_img").addClass('grid_1 alpha').appendTo(tweet_id);
  $('<div></div>').html("<span class=\"tweet_user\"><a href=\"http://twitter.com/"+result.from_user+"\">"+result.from_user+"</a></span><br />"+autolink(result.text)+"<br /><span class=\"tweet_date\">"+result.created_at+"</span>").addClass('grid_5 omega').appendTo(tweet_id);
  $('<a></a>').html("").attr('id',tweet_id_no_hash+"_img_a").attr('href',"http://twitter.com/"+result.from_user).attr('title',result.from_user).appendTo("#"+tweet_id_no_hash+"_img");
  $("<img/>").attr("src", result.profile_image_url).attr("height", "48").attr("width", "48").attr("alt", "").appendTo("#"+tweet_id_no_hash+"_img_a");
  $('<div></div>').html("").addClass("clear").appendTo(tweet_id);
  if(prepend) {
    $('<div></div>').html("").addClass("clear").prependTo("#topical_tweets");
  } else {
    $('<div></div>').html("").addClass("clear").appendTo("#topical_tweets");
  }
  if(quickly) {
    $(tweet_id).show();
  } else {
    $(tweet_id).slideDown(750, "easeOutExpo");
  }
}

function sort_tweets(tweets) {
  tweets.sort(sort_tweets_by_created_at);
}
function sort_tweets_by_created_at(a, b) {
  var x = a.created_at;
  var y = b.created_at;
  return ((x < y) ? -1 : ((x > y) ? 1 : 0));
}

function show_tweets(word_array) {
  tweets = [];
  max_id = 0;
  twitter_domain = "http://search.twitter.com/search.json";
  callback_parameters = "&callback=?";
  english_only = "&lang=en";
  twitter_url = twitter_domain + "?show_user=false&q=" + word_array.join('+') + callback_parameters;  
  twitter_url_hashtag = twitter_domain + "?show_user=false&q=%23" + word_array.sort().join('') + callback_parameters;  
  $.getJSON(twitter_url, function(data) {
    $('#loading_tweets').hide();  
    if(data.results.length > 0) {
      tweets = tweets.concat(data.results);
    } 
    twitter_url = twitter_domain + data.refresh_url + callback_parameters + english_only; // call this url next time for only new tweets
    max_id = data.max_id;
    sort_tweets(tweets);
  });
  $.getJSON(twitter_url_hashtag, function(data) {
    if(data.results.length > 0) {
      tweets = tweets.concat(data.results);
    } 
    twitter_url_hashtag = twitter_domain + data.refresh_url + callback_parameters + english_only; // call this url next time for only new tweets    
    sort_tweets(tweets);
  });
  $.timer(7000, function(timer) {
    if(tweets.length == 0) {
      $("#topical_tweets").html("<p></p>").html("Sorry, there are either no Tweets matching <strong>" + word_array.join(' ') + "</strong> or Twitter is experiencing problems.</p><p style=\"margin-top: 1.5em;\">Please try again in a few minutes.");
    }
    timer.stop();
  });
  $.timer(10000, function (timer) {  
    $.getJSON(twitter_url, function(data) {
      twitter_url = twitter_domain + data.refresh_url + callback_parameters + english_only; // call this url next time for only new tweets
      if(data.max_id > max_id) {
        max_id = data.max_id;
        if(data.results.length > 0) {
          tweets = tweets.concat(data.results);
        } 
      }
    });
    $.getJSON(twitter_url_hashtag, function(data) {
      twitter_url_hashtag = twitter_domain + data.refresh_url + callback_parameters + english_only; // call this url next time for only new tweets
      if(data.max_id > max_id) {
        max_id = data.max_id;
        if(data.results.length > 0) {
          tweets = tweets.concat(data.results);
        } 
      }
    });
    sort_tweets(tweets);
  });
  $.timer(1700, function(timer) {
    if(tweets.length > 0) {
      tweet_to_show = tweets.shift();
      display_tweet(tweet_to_show, true, false);
    }
  });
}