function should_page_be_updated(responseText) {
  if($('version_loaded').value != responseText) {
    if(! $('time_to_update')) {
      s = document.createElement("span");
      s.id = "time_to_update";
      s.style.display = "none";
      s.innerHTML = " <a href=\"/\">&larr; we've updated, refresh to get the new edition</a>";
      logo = $('logo');
      logo.appendChild(s);
      Effect.toggle('time_to_update','appear');
    }
  }
}

function update_time() {
  if($('time_ago')) {
    time_span = $('time_ago');
    time_span_content = time_span.innerHTML;
    if(time_span_content.match(/minutes/)) {
      [time, units] = time_span_content.split(/ /);
      time = parseInt(time) + 1;
      time_span.innerHTML = [time, units].join(" ");
    } 
  }
}
