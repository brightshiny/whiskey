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


// based on implementation from rails http://rails-doc.org/rails/ActionView/Helpers/DateHelper/distance_of_time_in_words
// explanation at http://blog.peelmeagrape.net/2008/7/26/time-ago-in-words-javascript-part-1
// unittests at http://blog.peelmeagrape.net/assets/2008/7/26/distanceOfTimeInWords.html
function distanceOfTimeInWords(fromTime, toTime, includeSeconds) {
  var fromSeconds = fromTime.getTime();
  var toSeconds = toTime.getTime();
  var distanceInSeconds = Math.round(Math.abs(fromSeconds - toSeconds) / 1000)
  var distanceInMinutes = Math.round(distanceInSeconds / 60)
  if (distanceInMinutes <= 1) {
    if (!includeSeconds)
      return (distanceInMinutes == 0) ? 'less than a minute' : '1 minute'
    if (distanceInSeconds < 5)
      return 'less than 5 seconds'
    if (distanceInSeconds < 10)
      return 'less than 10 seconds'
    if (distanceInSeconds < 20)
      return 'less than 20 seconds'
    if (distanceInSeconds < 40)
      return 'half a minute'
    if (distanceInSeconds < 60)
      return 'less than a minute'
    return '1 minute'
  }
  if (distanceInMinutes < 45)
    return distanceInMinutes + ' minutes'
  if (distanceInMinutes < 90)
    return "about 1 hour"
  if (distanceInMinutes < 1440)
    return "about " + (Math.round(distanceInMinutes / 60)) + ' hours'
  if (distanceInMinutes < 2880)
    return "1 day"
  if (distanceInMinutes < 43200)
    return (Math.round(distanceInMinutes / 1440)) + ' days'
  if (distanceInMinutes < 86400)
    return "about 1 month"
  if (distanceInMinutes < 525600)
    return (Math.round(distanceInMinutes / 43200)) + ' months'
  if (distanceInMinutes < 1051200)
    return "about 1 year"
  return "over " + (Math.round(distanceInMinutes / 525600)) + ' years'
}