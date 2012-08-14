// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var util = require('util');

var LDAPResult = require('./result');
var Protocol = require('../protocol');


///--- API

function ExtendedResponse(options) {
  if (options) {
    if (typeof(options) !== 'object')
      throw new TypeError('options must be an object');
    if (options.responseName && typeof(options.responseName) !== 'string')
      throw new TypeError('options.responseName must be a string');
    if (options.responseValue && typeof(options.responseValue) !== 'string')
      throw new TypeError('options.responseValue must be a string');
  } else {
    options = {};
  }

  this.responseName = options.responseName || undefined;
  this.responseValue = options.responseValue || undefined;

  options.protocolOp = Protocol.LDAP_REP_EXTENSION;
  LDAPResult.call(this, options);

  this.__defineGetter__('name', function() {
    return this.responseName;
  });
  this.__defineGetter__('value', function() {
    return this.responseValue;
  });
  this.__defineSetter__('name', function(name) {
    if (typeof(name) !== 'string')
      throw new TypeError('name must be a string');

    this.responseName = name;
  });
  this.__defineSetter__('value', function(val) {
    if (typeof(val) !== 'string')
      throw new TypeError('value must be a string');

    this.responseValue = val;
  });
}
util.inherits(ExtendedResponse, LDAPResult);
module.exports = ExtendedResponse;


ExtendedResponse.prototype._parse = function(ber) {
  assert.ok(ber);

  if (!LDAPResult.prototype._parse.call(this, ber))
    return false;

  if (ber.peek() === 0x8a)
    this.responseName = ber.readString(0x8a);
  if (ber.peek() === 0x8b)
    this.responseValue = ber.readString(0x8b);

  return true;
};


ExtendedResponse.prototype._toBer = function(ber) {
  assert.ok(ber);

  if (!LDAPResult.prototype._toBer.call(this, ber))
    return false;

  if (this.responseName)
    ber.writeString(this.responseName, 0x8a);
  if (this.responseValue)
    ber.writeString(this.responseValue, 0x8b);

  return ber;
};


ExtendedResponse.prototype._json = function(j) {
  assert.ok(j);

  j = LDAPResult.prototype._json.call(this, j);

  j.responseName = this.responseName;
  j.responseValue = this.responseValue;

  return j;
};
