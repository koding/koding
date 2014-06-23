var origin = window.location.origin;

var sock = new SockJS(origin+'/echo')

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
	document.getElementById("status").innerHTML = "disconnected";
	document.getElementById("send").disabled=true;
};

function send() {
	text = document.getElementById("input").value;
	sock.send(text);
}
