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


///--- API

function ModifyDNRequest(options) {
  if (options) {
    if (typeof(options) !== 'object')
      throw new TypeError('options must be an object');
    if (options.entry && !(options.entry instanceof dn.DN))
      throw new TypeError('options.entry must be a DN');
    if (options.newRdn && !(options.newRdn instanceof dn.DN))
      throw new TypeError('options.newRdn must be a DN');
    if (options.deleteOldRdn !== undefined &&
        typeof(options.deleteOldRdn) !== 'boolean')
      throw new TypeError('options.deleteOldRdn must be a boolean');
    if (options.newSuperior && !(options.newSuperior instanceof dn.DN))
      throw new TypeError('options.newSuperior must be a DN');

  } else {
    options = {};
  }

  options.protocolOp = Protocol.LDAP_REQ_MODRDN;
  LDAPMessage.call(this, options);

  this.entry = options.entry || null;
  this.newRdn = options.newRdn || null;
  this.deleteOldRdn = options.deleteOldRdn || true;
  this.newSuperior = options.newSuperior || null;

  var self = this;
  this.__defineGetter__('type', function() { return 'ModifyDNRequest'; });
  this.__defineGetter__('_dn', function() { return self.entry; });
}
util.inherits(ModifyDNRequest, LDAPMessage);
module.exports = ModifyDNRequest;


ModifyDNRequest.prototype._parse = function(ber) {
  assert.ok(ber);

  this.entry = dn.parse(ber.readString());
  this.newRdn = dn.parse(ber.readString());
  this.deleteOldRdn = ber.readBoolean();
  if (ber.peek() === 0x80)
    this.newSuperior = dn.parse(ber.readString(0x80));

  return true;
};


ModifyDNRequest.prototype._toBer = function(ber) {
  assert.ok(ber);

  ber.writeString(this.entry.toString());
  ber.writeString(this.newRdn.toString());
  ber.writeBoolean(this.deleteOldRdn);
  if (this.newSuperior)
    ber.writeString(this.newSuperior.toString());

  return ber;
};


ModifyDNRequest.prototype._json = function(j) {
  assert.ok(j);

  j.entry = this.entry.toString();
  j.newRdn = this.newRdn.toString();
  j.deleteOldRdn = this.deleteOldRdn;
  j.newSuperior = this.newSuperior ? this.newSuperior.toString() : '';

  return j;
};
