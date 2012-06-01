/*
 * querystring-parse.js
 *  - node.js module providing "parse" method to turn query strings into js objects
 *
 * Chad Etzel
 *
 * Based on YUI "querystring-parse.js" module
 * http://github.com/isaacs/yui3/tree/master/src/querystring/js
 *
 * Copyright (c) 2009, Yahoo! Inc. and Chad Etzel
 * BSD License (see LICENSE.md for info)
 */


var sys = require("sys"),
  util = require("./util");

exports.parse = querystring_parse;

/**
 * <p>The querystring module adds support for serializing JavaScript objects into
 * query strings and parsing JavaScript objects from query strings format.</p>
 *
 * <p>The <code>querystring</code> module is a rollup of <code>querystring-parse</code> and
 * <code>querystring-stringify</code>.</p>
 * 
 * <p>As their names suggest, <code>querystring-parse</code> adds support for parsing
 * Query String data (querystring.parse) and <code>querystring-stringify</code> for serializing
 * JavaScript data into Query Strings (querystring.stringify).  You may choose to
 * include either of the submodules individually if you don't need the
 * complementary functionality, or include the rollup for both.</p>
 *
 * @module querystring
 */

/**
 * Provides parse method to accept Query Strings and return native
 * JavaScript objects.
 *
 * @module querystring
 * @submodule querystring-parse
 * @for querystring
 * @static
 */
function querystring_parse (qs, sep, eq, unesc) {
  return qs.split(sep || "&")
    .map(pieceParser(eq || "=", unesc || unescape))
    .reduce(mergeParams, {});
};

function unescape (s) {
    return decodeURIComponent(s.replace(/\+/g, ' '));
};


// Parse a key=val string.
// These can get pretty hairy
// example flow:
// parse(foo[bar][][bla]=baz)
// return parse(foo[bar][][bla],"baz")
// return parse(foo[bar][], {bla : "baz"})
// return parse(foo[bar], [{bla:"baz"}])
// return parse(foo, {bar:[{bla:"baz"}]})
// return {foo:{bar:[{bla:"baz"}]}}
function pieceParser (eq, unesc) {
  return function parsePiece (key, val) {
    if (arguments.length !== 2) {
      // key=val, called from the map/reduce
      key = key.split(eq);
      return parsePiece(
        unesc(key.shift()),
        unesc(key.join(eq))
      );
    }
    key = key.replace(/^\s+|\s+$/g, '');
    if (util.isString(val)) {
      val = val.replace(/^\s+|\s+$/g, '');
      // convert numerals to numbers
      if (!isNaN(val)) {
        var numVal = +val;
        if (val === numVal.toString(10)) val = numVal;
      }
    }
    var sliced = /(.*)\[([^\]]*)\]$/.exec(key);
    if (!sliced) {
      var ret = {};
      if (key) ret[key] = val;
      return ret;
    }
    // ["foo[][bar][][baz]", "foo[][bar][]", "baz"]
    var tail = sliced[2],
      head = sliced[1];

    // array: key[]=val
    if (!tail) return parsePiece(head, [val]);

    // obj: key[subkey]=val
    var ret = {};
    ret[tail] = val;
    return parsePiece(head, ret);
  };
};

// the reducer function that merges each query piece together into one set of params
function mergeParams (params, addition) {
	var ret;
			
	if (!params){
		// if it's uncontested, then just return the addition.
		ret = addition;
	} else if (util.isArray(params)) {
		// if the existing value is an array, then concat it.
		ret = params.concat(addition);
	} else if (!util.isObject(params) || !util.isObject(addition)) {
		// if the existing value is not an array, and either are not objects, arrayify it.		
		ret = [params].concat(addition);
	} else {
		// else merge them as objects, which is a little more complex
		ret = mergeObjects(params, addition);
	}
	return ret;
};


// Merge two *objects* together. If this is called, we've already ruled
// out the simple cases, and need to do the for-in business.
function mergeObjects (params, addition) {
  for (var i in addition) if (i && addition.hasOwnProperty(i)) {
    params[i] = mergeParams(params[i], addition[i]);
  }
  return params;
};
