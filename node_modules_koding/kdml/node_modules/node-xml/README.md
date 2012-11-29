node-xml
===================

(C) Rob Righter (@robrighter) 2009 - 2010, Licensed under the MIT-LICENSE
Contributions from David Joham

 node-xml is an xml parser for node.js written in javascript. 

 
API
---
 

SaxParser
---------

Node-xml provides a SAX2 parser interface that can take a string, file. The parser can take characters from the document in chunks. To send chunks of the document to the parser use 'parseString(xml)'

#SAX Parser#

##new xml.SaxParser()##
	* Instantiate a new SaxParser
	* returns: a SaxParser object

##new xml.SaxParser(callback)##
	* Instantiate a new SaxParser
	* returns: a SaxParser object
	* Arguments
		*callback - a function that accepts the new sax parser as an argument
	
#Parse#

##parser.parseString(string)##

Parse an in memory string
* return: boolean. true if no errors, false otherwise
* Arguments
	* string - a string representing the document to parse

##parser.parseFile(filename)##

Parse a file
* return: boolean. true if no errors, false otherwise
* Arguments
	* filename - a string representing the file to be parsed
	
##parser.pause()##
pauses parsing of the document

##parser.resume()##
resumes parsing of the document

#Callbacks#

##parser.onStartDocument(function() {})##

Called at the start of a document

##parse.onEndDocument(function() {})##

 Called at the end of the document parse

##parser.onStartElementNS(function(elem, attrs, prefix, uri, namespaces) {})##

Called on an open element tag
* Arguments
	* elem - a string representing the element name
	* attrs - an array of arrays: [[key, value], [key, value]]
	* prefix - a string representing the namespace prefix of the element
	* uri - the namespace URI of the element
	* namespaces - an array of arrays: [[prefix, uri], [prefix, uri]]

##parser.onEndElementNS(function(elem, prefix, uri) {})##

Called at the close of an element
* Arguments
	* elem - a string representing the element name
    * prefix - a string representing the namespace prefix of the element
    * uri - the namespace URI of the element

##parser.onCharacters(function(chars) {})##

Called when a set of content characters is encountered
* Arguments
	* chars - a string of characters

##parser.onCdata(function(cdata) {})##

Called when a CDATA is encountered
* Arguments
	* cdata - a string representing the CDATA

##parser.onComment(function(msg) {})##

Called when a comment is encountered
* Arguments
	* msg - a string representing the comment

##parser.onWarning(function(msg) {})##

Called when a warning is encountered
* Arguments
	* msg - a string representing the warning message

##parser.onError(function(msg) {})##

Called when an error is encountered
   * Arguments
		* msg - a string representing the error message
	

EXAMPLE USAGE
-------------

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
	         setTimeout(function (){parser.resume();}, 200); //resume the parser
	  });
	  cb.onCharacters(function(chars) {
	      //util.log('<CHARS>'+chars+"</CHARS>");
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

	//example read from file
	parser.parseFile("sample.xml");
