/*
 * querystring.js
 *  - node.js module providing "parse" and "stringify" methods 
 *    to turn query strings into objects and to turn objects 
 *    into query string, respectively
 *
 *  This module is basically a stub loader. It will load both
 *  sub-modules and put the respective exports under the same
 *  namespace.  You may choose to load the sub-modules
 *  individually if you only need the functionality of one.
 *
 * Chad Etzel
 *
 * Based on YUI "querystring-parse.js" module
 * http://github.com/isaacs/yui3/tree/master/src/querystring/js
 *
 * Copyright (c) 2009, Yahoo! Inc. and Chad Etzel
 * BSD License (see LICENSE.md for info)
 *
 */

[
  require("./querystring-parse"),
  require("./querystring-stringify")
].forEach(function (q) {
  for (var i in q) if (q.hasOwnProperty(i)) exports[i] = q[i];
});
