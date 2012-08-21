// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var util = require('util');

var LDAPResult = require('./result');
var Protocol = require('../protocol');


///--- API

function ModifyDNResponse(options) {
  if (options) {
    if (typeof(options) !== 'object')
      throw new TypeError('options must be an object');
  } else {
    options = {};
  }

  options.protocolOp = Protocol.LDAP_REP_MODRDN;
  LDAPResult.call(this, options);
}
util.inherits(ModifyDNResponse, LDAPResult);
module.exports = ModifyDNResponse;
