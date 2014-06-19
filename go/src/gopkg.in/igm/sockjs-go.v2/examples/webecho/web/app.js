var origin = window.location.origin;

// options usage example
var options = {
		debug: true,
		devel: true,
		protocols_whitelist: ['websocket', 'xdr-streaming', 'xhr-streaming', 'iframe-eventsource', 'iframe-htmlfile', 'xdr-polling', 'xhr-polling', 'iframe-xhr-polling', 'jsonp-polling']
};

var sock = new SockJS(origin+'/echo', undefined, options);

document.getElementById("input").onkeydown= function (e) {
	if (e.keyCode === 13) {
		send();
		e.target.value="";
	};
}; 
document.getElementById("input").focus();

sock.onopen = function() {
	console.log('connection open');
	document.getElementById("status").innerHTML = "connected";
	document.getElementById("send").disabled=false;
};

sock.onmessage = function(e) {
	document.getElementById("output").value += e.data +"\n";
};

sock.onclose = function() {
	console.log('connection closed');
};

function send() {
	text = document.getElementById("input").value;
	sock.send(text);
}
