// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var dtrace = require('dtrace-provider');



///--- Globals

var SERVER_PROVIDER;
var DTRACE_ID = 0;
var MAX_INT = 4294967295;

/* Args:
 * server-*-start:
 * 0 -> id
 * 1 -> remoteIP
 * 2 -> bindDN
 * 3 -> req.dn
 * 4,5 -> op specific
 *
 * server-*-done:
 * 0 -> id
 * 1 -> remoteIp
 * 2 -> bindDN
 * 3 -> requsetDN
 * 4 -> status
 * 5 -> errorMessage
 *
 */
var SERVER_PROBES = {

  // 4: attributes.length
  'server-add-start': ['int', 'char *', 'char *', 'char *', 'int'],
  'server-add-done': ['int', 'char *', 'char *', 'char *', 'int', 'char *'],

  'server-bind-start': ['int', 'char *', 'char *', 'char *'],
  'server-bind-done': ['int', 'char *', 'char *', 'char *', 'int', 'char *'],

  // 4: attribute, 5: value
  'server-compare-start': ['int', 'char *', 'char *', 'char *',
                           'char *', 'char *'],
  'server-compare-done': ['int', 'char *', 'char *', 'char *', 'int', 'char *'],

  'server-delete-start': ['int', 'char *', 'char *', 'char *'],
  'server-delete-done': ['int', 'char *', 'char *', 'char *', 'int', 'char *'],

  // 4: requestName, 5: requestValue
  'server-exop-start': ['int', 'char *', 'char *', 'char *', 'char *',
                        'char *'],
  'server-exop-done': ['int', 'char *', 'char *', 'char *', 'int', 'char *'],

  // 4: changes.length
  'server-modify-start': ['int', 'char *', 'char *', 'char *', 'int'],
  'server-modify-done': ['int', 'char *', 'char *', 'char *', 'int', 'char *'],

  // 4: newRdn, 5: newSuperior
  'server-modifydn-start': ['int', 'char *', 'char *', 'char *', 'char *',
                            'char *'],
  'server-modifydn-done': ['int', 'char *', 'char *', 'char *', 'int',
                           'char *'],

  // 4: scope, 5: filter
  'server-search-start': ['int', 'char *', 'char *', 'char *', 'char *',
                          'char *'],
  'server-search-done': ['int', 'char *', 'char *', 'char *', 'int', 'char *'],
  // Last two are searchEntry.DN and seachEntry.attributes.length
  'server-search-entry': ['int', 'char *', 'char *', 'char *', 'char *', 'int'],

  'server-unbind-start': ['int', 'char *', 'char *', 'char *'],
  'server-unbind-done': ['int', 'char *', 'char *', 'char *', 'int', 'char *'],

  // remote IP
  'server-connection': ['char *']
};


///--- API

module.exports = function() {
  if (!SERVER_PROVIDER) {
    SERVER_PROVIDER = dtrace.createDTraceProvider('ldapjs');

    Object.keys(SERVER_PROBES).forEach(function(p) {
      var args = SERVER_PROBES[p].splice(0);
      args.unshift(p);

      dtrace.DTraceProvider.prototype.addProbe.apply(SERVER_PROVIDER, args);
    });

    SERVER_PROVIDER.enable();

    SERVER_PROVIDER._nextId = function() {
      if (DTRACE_ID === MAX_INT)
        DTRACE_ID = 0;

      return ++DTRACE_ID;
    };
  }

  return SERVER_PROVIDER;
}();

