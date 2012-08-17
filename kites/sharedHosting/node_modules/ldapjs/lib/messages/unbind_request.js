// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var util = require('util');

var asn1 = require('asn1');

var LDAPMessage = require('./message');
var LDAPResult = require('./result');

var dn = require('../dn');
var Protocol = require('../protocol');



///--- Globals

var Ber = asn1.Ber;

var DN = dn.DN;
var RDN = dn.RDN;


///--- API

function UnbindRequest(options) {
  if (options) {
    if (typeof(options) !== 'object')
      throw new TypeError('options must be an object');
  } else {
    options = {};
  }

  options.protocolOp = Protocol.LDAP_REQ_UNBIND;
  LDAPMessage.call(this, options);

  var self = this;
  this.__defineGetter__('type', function() { return 'UnbindRequest'; });
  this.__defineGetter__('_dn', function() {
    if (self.connection)
      return self.connection.ldap.bindDN;

    return new DN([new RDN({cn: 'anonymous'})]);
  });
}
util.inherits(UnbindRequest, LDAPMessage);
module.exports = UnbindRequest;


UnbindRequest.prototype.newResult = function() {
  var self = this;

  // This one is special, so just hack up the result object
  function UnbindResponse(options) {
    LDAPMessage.call(this, options);
    this.__defineGetter__('type', function() { return 'UnbindResponse'; });
  }
  util.inherits(UnbindResponse, LDAPMessage);
  UnbindResponse.prototype.end = function(status) {
    if (this.log.isTraceEnabled())
      log.trace('%s: unbinding!', this.connection.ldap.id);
    this.connection.end();
  };
  UnbindResponse.prototype._json = function(j) { return j; };

  return new UnbindResponse({
    messageID: 0,
    protocolOp: 0,
    status: 0 // Success
  });
};


UnbindRequest.prototype._parse = function(ber) {
  assert.ok(ber);

  return true;
};


UnbindRequest.prototype._toBer = function(ber) {
  assert.ok(ber);

  return ber;
};


UnbindRequest.prototype._json = function(j) {
  assert.ok(j);

  return j;
};
