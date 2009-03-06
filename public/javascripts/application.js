function should_page_be_updated(responseText) {
  if($('version_loaded').value != responseText) {
    if(! $('time_to_update')) {
      s = document.createElement("span");
      s.id = "time_to_update";
      s.innerHTML = " &larr; we've updated, refresh to get the latest edition";
      s.style.display = "none";
      logo = $('logo');
      logo.appendChild(s);
      Effect.toggle('time_to_update','appear');
    }
  }
}
