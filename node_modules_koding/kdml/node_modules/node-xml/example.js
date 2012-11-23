var util = require('util');
var xml = require("./lib/node-xml");

var parser = new xml.SaxParser(function(cb) {
  cb.onStartDocument(function() {
      
  });
  cb.onEndDocument(function() {
      
  });
  cb.onStartElementNS(function(elem, attrs, prefix, uri, namespaces) {
      util.log("=> Started: " + elem + " uri="+uri +" (Attributes: " + JSON.stringify(attrs) + " )");
  });
  cb.onEndElementNS(function(elem, prefix, uri) {
      util.log("<= End: " + elem + " uri="+uri + "\n");
         parser.pause();// pause the parser
         setTimeout(function (){parser.resume();}, 100); //resume the parser
  });
  cb.onCharacters(function(chars) {
      util.log('<CHARS>'+chars+"</CHARS>");
  });
  cb.onCdata(function(cdata) {
      util.log('<CDATA>'+cdata+"</CDATA>");
  });
  cb.onComment(function(msg) {
      util.log('<COMMENT>'+msg+"</COMMENT>");
  });
  cb.onWarning(function(msg) {
      util.log('<WARNING>'+msg+"</WARNING>");
  });
  cb.onError(function(msg) {
      util.log('<ERROR>'+JSON.stringify(msg)+"</ERROR>");
  });
});


//example read from file
parser.parseFile("sample.xml");

//example read from chunks
parser.parseString("<html><body>");
parser.parseString("<!-- This is the start");
parser.parseString(" and the end of a comment -->");
parser.parseString("and lots");
parser.parseString("and lots of text&am");
parser.parseString("p;some more.");
parser.parseString("<![CD");
parser.parseString("ATA[ this is");
parser.parseString(" cdata ]]>");
parser.parseString("</body");
parser.parseString("></html>");




