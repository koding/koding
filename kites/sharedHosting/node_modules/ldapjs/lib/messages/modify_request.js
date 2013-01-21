// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var util = require('util');

var LDAPMessage = require('./message');
var LDAPResult = require('./result');

var dn = require('../dn');
var Change = require('../change');
var Protocol = require('../protocol');



///--- API

function ModifyRequest(options) {
  if (options) {
    if (typeof(options) !== 'object')
      throw new TypeError('options must be an object');
    if (options.object && !(options.object instanceof dn.DN))
      throw new TypeError('options.object must be a DN');
    if (options.attributes) {
      if (!Array.isArray(options.attributes))
        throw new TypeError('options.attributes must be [Attribute]');
      options.attributes.forEach(function(a) {
        if (!(a instanceof Attribute))
          throw new TypeError('options.attributes must be [Attribute]');
      });
    }
  } else {
    options = {};
  }

  options.protocolOp = Protocol.LDAP_REQ_MODIFY;
  LDAPMessage.call(this, options);

  this.object = options.object || null;
  this.changes = options.changes ? options.changes.slice(0) : [];

  var self = this;
  this.__defineGetter__('type', function() { return 'ModifyRequest'; });
  this.__defineGetter__('_dn', function() { return self.object; });
}
util.inherits(ModifyRequest, LDAPMessage);
module.exports = ModifyRequest;


ModifyRequest.prototype._parse = function(ber) {
  assert.ok(ber);

  this.object = dn.parse(ber.readString());

  ber.readSequence();
  var end = ber.offset + ber.length;
  while (ber.offset < end) {
    var c = new Change();
    c.parse(ber);
    c.modification.type = c.modification.type.toLowerCase();
    this.changes.push(c);
  }

  this.changes.sort(Change.compare);
  return true;
};


ModifyRequest.prototype._toBer = function(ber) {
  assert.ok(ber);

  ber.writeString(this.object.toString());
  ber.startSequence();
  this.changes.forEach(function(c) {
    c.toBer(ber);
  });
  ber.endSequence();

  return ber;
};


ModifyRequest.prototype._json = function(j) {
  assert.ok(j);

  j.object = this.object;
  j.changes = [];

  this.changes.forEach(function(c) {
    j.changes.push(c.json);
  });

  return j;
};
