# Simple SAX-based XML2JSON Parser.

It does not parse the following elements: 

* CDATA sections
* Processing instructions
* XML declarations
* Entity declarations
* Comments

## Installation 
`npm install xml2json`

## Usage 
```javascript
var parser = require('xml2json');

var xml = "<foo>bar</foo>";
var json = parser.toJson(xml); //returns an string containing the json structure by default
console.log(json);
```
* if you want to get the Javascript object then you might want to invoke parser.toJson(xml, {object: true});
* if you want a reversible json to xml then you should use parser.toJson(xml, {reversible: true});


## License
Copyright 2011 BugLabs Inc. All rights reserved.
