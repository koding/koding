var Terminal = require('./terminal').Terminal
var HTML = require("./htmlify");
function displayHtmlScreen(screen){
        var cursor=screen.cursor();
	console.log("Screen:##################################");
        console.log("cursor {row:"+cursor.row+",col:"+cursor.col+"} window size {rows:"+screen.rows+",cols:"+screen.cols+"}");
	var html=HTML.convert(screen);
	console.log(html);
	console.log("###########################################");
}

var terminal = new Terminal("/bin/bash",70,90);
var size=terminal.getScreenSize();
console.log("Terminal initialized : \n");
console.log("window [rows="+size.rows+",cols="+size.cols+"]");

displayHtmlScreen(terminal.getScreen());
terminal.send("ls\n",3);
setTimeout(function(){
	displayHtmlScreen(terminal.getScreen());
}, 500); //wait to ensure that command was executed



