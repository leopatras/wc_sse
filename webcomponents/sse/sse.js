var _theinput=document.getElementById("theinput")
var _source=null;
function mylog(s) {
  console.log(s);
}
//SSE events
function addEventSource(url) {
  //myassert(_source===null);
  var source = new EventSource(url);
  source.addEventListener('code', function(e) {
    var id = e.lastEventId;
    var data = e.data;
    mylog("SSE data:'"+typeof data+","+data+",id:"+id);
    theinput.value=data;
    gICAPI.SetData(data);
    gICAPI.Action("data_available");
    if (e.data == "http404" ) {
      mylog("session ended, finally close source");
      closeSource();
    } else {
      reAddSource(url,true);
    }
  });
  source.addEventListener('error', function(e) {
    mylog("err readyState:"+e.target.readyState);
    if (e.target.readyState == EventSource.CLOSED) {
      mylog("EventSource closed");
    }
    mylog(" close SSE due to an error(server not reachable)");
    closeSource();
  });
  _source=source;
  mylog("added eventsource at url:"+url);
}
function closeSource() {
  if (_source) {
    _source.close()
  }
  _source=null;
}

function reAddSource(url) { //needed for firefox: ignores the retry param
  //which means each SSE event causes the SSE listeners to be added again
  mylog("reAddSource:");
  closeSource();
  addEventSource(url);
}

onICHostReady = function(version) {
  gICAPI.onData = function(data) {
    theinput.data=data;
  }
  gICAPI.onFocus = function(polarity) {
    gICAPI.SetFocus();
  }

  gICAPI.onFlushData = function() {
    gICAPI.SetData(theinput.value);
  }

  gICAPI.onStateChanged=function(s) {
    var obj = JSON.parse(s);
    var active = obj.active;
    theinput.disabled=!active;
  }

  gICAPI.onProperty = function(p) {
  }
}

function setURL(url) {
  addEventSource(url);
}
