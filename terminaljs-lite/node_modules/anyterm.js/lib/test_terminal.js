var Terminal = require('./terminal').Terminal
var htmlify = require("./htmlify")

function displayScreen(screen){
	console.log("Screen:##################################");
	for(i=0;i<screen.rows;i++){
		console.log(screen.row(i));
	}
	console.log("###########################################");
}


{
var terminal = new Terminal("/bin/bash",70,90);

console.log("Testing events");


terminal.on("screenDidChange",function(screen,data){
    console.log(">Ready event triggered custom data=["+data+"]");
    displayScreen(screen);
    delete screen;
});

terminal.emit("screenDidChange","some custom data");

terminal.on("close",function(data){
    console.log(">onClose event triggered, custom data=["+data+"]");
});

var size=terminal.getScreenSize();
console.log("Terminal initialized : \n");
console.log("window [rows="+size.rows+",cols="+size.cols+"]");

displayScreen(terminal.getScreen());

terminal.send("top\n");
setTimeout(function(){
    displayScreen(terminal.getScreen());
    terminal.setScreenSize(10,10);
    displayScreen(terminal.getScreen());
    terminal.kill();
    console.log("process should be killed...");
    setTimeout(function(){
        console.log("deleting object ...");
        delete terminal;
        setTimeout(function(){
            console.log("all done");
        },200);
    },300);
},500);


}
