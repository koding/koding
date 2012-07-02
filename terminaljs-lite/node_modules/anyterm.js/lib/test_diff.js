var Diff = require("./diff");

var str1="this is a test";

var str2="antother test it is";

console.log("str1="+str1);
console.log("str2="+str2);
console.log("Parsing differences: ");

Diff.parseDiff(str1,str2,function(type,str){
	console.log("DIFF  ###################################");
	console.log("type=["+type+"]"+(type==0?'remove':(type==2?'keep':'add')));
	console.log("str="+str);
});
