var sys = require('sys');
var node_xml = require("node-xml");
var libxml = require("libxmljs");
var expat = require('./lib/node-expat');

function NodeXmlParser() {
    var parser = new node_xml.SaxParser(function(cb) { });
    this.parse = function(s) {
	parser.parseString(s);
    };
}
function LibXmlJsParser() {
    var parser = new libxml.SaxPushParser(function(cb) { });
    this.parse = function(s) {
	parser.push(s, false);
    };
}
function ExpatParser() {
    var parser = new expat.Parser();
    this.parse = function(s) {
	parser.parse(s, false);
    };
}

//var p = new NodeXmlParser();
//var p = new LibXmlJsParser();
var p = new ExpatParser();
p.parse("<r>");
var nEl = 0;
function d() {
    p.parse("<foo bar='baz'>quux</foo>");
    nEl++;
    setTimeout(d, 0);
}
d();

setInterval(function() {
    sys.puts(nEl + " el/s");
    nEl = 0;
}, 1000);