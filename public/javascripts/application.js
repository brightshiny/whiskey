function should_page_be_updated(responseText) {
  if($('version_loaded').value != responseText) {
    if(! $('time_to_update')) {
      s = document.createElement("span");
      s.id = "time_to_update";
      s.style.display = "none";
      s.innerHTML = " <a href=\"/\">&larr; we've updated, refresh to get the latest edition</a>";
      logo = $('logo');
      logo.appendChild(s);
      Effect.toggle('time_to_update','appear');
    }
  }
}
