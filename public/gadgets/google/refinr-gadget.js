var refinr_gadget_data_src = "http://refinr.com/site.js";
window.refinr_gadget_container = document.getElementById("refinr_gadget_container");

function makeJSONRequest() {    
  var params = {};
  params[gadgets.io.RequestParameters.CONTENT_TYPE] = gadgets.io.ContentType.JSON;
  // This URL returns a JSON-encoded string that represents a JavaScript object
  var url = "http://refinr.com/site.js";
  gadgets.io.makeRequest(url, response, params);
}

// function refinr_gadget_data_init(data) {
function response(obj) {  
  data = obj.data.top_stories;
  window.refinr_gadget_container.innerHTML = "";
  window.refinr_data = obj;
  if(data) {
    var ul = document.createElement("ul");
    for(var i=0;i<data.length;i++) {
      var li = document.createElement("li");
      var s = document.createElement("span");
      var a  = document.createElement("a");
      a.href = data[i].item.link;
      a.setAttribute('onclick', 'track_click("http://refinr.com/c/' + data[i].item.encrypted_id + '", "' + data[i].item.title + '")');      
      var img = document.createElement('img');
      if(data[i].item.feed.logo) {
        img.src = "http://media.refinr.com" + data[i].item.feed.logo;
      } else {
        img.src = "http://media.refinr.com/assets/images/fauxvicon.gif";
      }
      img.width = "16";
      img.height = "16";
      a.appendChild(img);
      var a_t = document.createTextNode(data[i].item.title);
      a.appendChild(a_t);
      s.appendChild(a);
      if(data[i].item.author) {
        var s_t = document.createTextNode(" " + data[i].item.author);
        s.appendChild(s_t);
      }
      var d = document.createElement('span');
      d.className = "published_at";
      var d_t = document.createTextNode(" " + data[i].item.published_date);
      d.appendChild(d_t);
      s.appendChild(d);
      li.appendChild(s);
      ul.appendChild(li);
    }
    window.refinr_gadget_container.appendChild(ul);
  } else {
    document.write("Error connecting to refinr.com, please try again later");
  }
  setTimeout("gadgets.window.adjustHeight()", 200);
}

function track_click(src, link_name) {
	if(document.images) {
		(new Image()).src = src;
	}
	if (pageTracker) {
		pageTracker._trackPageview(link_name)
	}
}
  
if(window.refinr_gadget_container) {
  makeJSONRequest();
  // var script_tag = document.createElement('script');
  // script_tag.type = "text/javascript";
  // script_tag.src = refinr_gadget_data_src;
  // window.refinr_gadget_container.appendChild(script_tag);  
}
