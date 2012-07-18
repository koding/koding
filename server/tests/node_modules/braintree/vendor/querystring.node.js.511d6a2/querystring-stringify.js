/*
 * querystring-stringify.js
 *   - node.js module providing 'stringify' method for converting objects to query strings.
 *
 * Chad Etzel
 *
 * Based on YUI "querystring-stringify.js" module
 * http://github.com/isaacs/yui3/tree/master/src/querystring/js
 *
 * Copyright (c) 2009, Yahoo! Inc. and Chad Etzel
 * BSD License (see LICENSE.md for info)
 *
 */

var util = require("./util");

exports.stringify = querystring_stringify;

var stack = [];
/**
 * <p>Converts an arbitrary value to a Query String representation.</p>
 *
 * <p>Objects with cyclical references will trigger an exception.</p>
 *
 * @method stringify
 * @param obj {Variant} any arbitrary value to convert to query string
 * @param sep {String} (optional) Character that should join param k=v pairs together. Default: "&"
 * @param eq  {String} (optional) Character that should join keys to their values. Default: "="
 * @param name {String} (optional) Name of the current key, for handling children recursively.
 * @param escape {Function} (optional) Function for escaping. Default: encodeURIComponent
 */
function querystring_stringify (obj, sep, eq, name, escape) {
  sep = sep || "&";
  eq = eq || "=";
  escape = escape || encodeURIComponent;
  
  if (util.isNull(obj) || util.isUndefined(obj) || typeof(obj) === 'function') {
    return name ? escape(name) + eq : '';
  }
  
  if (util.isBoolean(obj)) obj = +obj;
  if (util.isNumber(obj) || util.isString(obj)) {
    return escape(name) + eq + escape(obj);
  }  
  if (util.isArray(obj)) {
    var s = [];
    name = name+'[]';
    for (var i = 0, l = obj.length; i < l; i ++) {
      s.push( querystring_stringify(obj[i], sep, eq, name, escape) );
    }
    return s.join(sep);
  }
  
  // Check for cyclical references in nested objects
  for (var i = stack.length - 1; i >= 0; --i) if (stack[i] === obj) {
    throw new Error("querystring_stringify. Cyclical reference");
  }
  
  stack.push(obj);
  
  var s = [];
  var begin = name ? name + '[' : '';
  var end = name ? ']' : '';
  for (var i in obj) if (obj.hasOwnProperty(i)) {
    var n = begin + i + end;
    s.push(querystring_stringify(obj[i], sep, eq, n, escape));
  }
  
  stack.pop();
  
  s = s.join(sep);
  if (!s && name) return name + "=";
  return s;
};

