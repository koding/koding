// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var util = require('util');

var LDAPMessage = require('./message');
var LDAPResult = require('./result');

var dn = require('../dn');
var Protocol = require('../protocol');



///--- API

function CompareRequest(options) {
  if (options) {
    if (typeof(options) !== 'object')
      throw new TypeError('options must be an object');
    if (options.entry && !(options.entry instanceof dn.DN))
      throw new TypeError('options.entry must be a DN');
    if (options.attribute && typeof(options.attribute) !== 'string')
      throw new TypeError('options.attribute must be a string');
    if (options.value && typeof(options.value) !== 'string')
      throw new TypeError('options.value must be a string');
  } else {
    options = {};
  }

  options.protocolOp = Protocol.LDAP_REQ_COMPARE;
  LDAPMessage.call(this, options);

  this.entry = options.entry || null;
  this.attribute = options.attribute || '';
  this.value = options.value || '';

  var self = this;
  this.__defineGetter__('type', function() { return 'CompareRequest'; });
  this.__defineGetter__('_dn', function() {
    return self.entry ? self.entry.toString() : '';
  });
}
util.inherits(CompareRequest, LDAPMessage);
module.exports = CompareRequest;


CompareRequest.prototype._parse = function(ber) {
  assert.ok(ber);

  this.entry = dn.parse(ber.readString());

  ber.readSequence();
  this.attribute = ber.readString().toLowerCase();
  this.value = ber.readString();

  return true;
};


CompareRequest.prototype._toBer = function(ber) {
  assert.ok(ber);

  ber.writeString(this.entry.toString());
  ber.startSequence();
  ber.writeString(this.attribute);
  ber.writeString(this.value);
  ber.endSequence();

  return ber;
};


CompareRequest.prototype._json = function(j) {
  assert.ok(j);

  j.entry = this.entry.toString();
  j.attribute = this.attribute;
  j.value = this.value;

  return j;
};
