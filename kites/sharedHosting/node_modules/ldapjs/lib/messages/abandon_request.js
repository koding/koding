// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var util = require('util');

var asn1 = require('asn1');

var LDAPMessage = require('./message');
var LDAPResult = require('./result');

var dn = require('../dn');
var Attribute = require('../attribute');
var Protocol = require('../protocol');

///--- Globals

var Ber = asn1.Ber;



///--- API

function AbandonRequest(options) {
  if (options) {
    if (typeof(options) !== 'object')
      throw new TypeError('options must be an object');
    if (options.abandonID && typeof(options.abandonID) !== 'number')
      throw new TypeError('abandonID must be a number');
  } else {
    options = {};
  }

  options.protocolOp = Protocol.LDAP_REQ_ABANDON;
  LDAPMessage.call(this, options);

  this.abandonID = options.abandonID || 0;

  var self = this;
  this.__defineGetter__('type', function() { return 'AbandonRequest'; });
}
util.inherits(AbandonRequest, LDAPMessage);
module.exports = AbandonRequest;


AbandonRequest.prototype._parse = function(ber, length) {
  assert.ok(ber);
  assert.ok(length);

  // What a PITA - have to replicate ASN.1 integer logic to work around the
  // way abandon is encoded and the way ldapjs framework handles "normal"
  // messages

  var buf = ber.buffer;
  var offset = 0;
  var value = 0;

  var fb = buf[offset++];
  value = fb & 0x7F;
  for (var i = 1; i < length; i++) {
    value <<= 8;
    value |= (buf[offset++] & 0xff);
  }
  if ((fb & 0x80) == 0x80)
    value = -value;

  ber._offset += length;

  this.abandonID = value;

  return true;
};


AbandonRequest.prototype._toBer = function(ber) {
  assert.ok(ber);

  var i = this.abandonID;
  var sz = 4;

  while ((((i & 0xff800000) == 0) || ((i & 0xff800000) == 0xff800000)) &&
         (sz > 1)) {
    sz--;
    i <<= 8;
  }
  assert.ok(sz <= 4);

  while (sz-- > 0) {
    ber.writeByte((i & 0xff000000) >> 24);
    i <<= 8;
  }

  return ber;
};


AbandonRequest.prototype._json = function(j) {
  assert.ok(j);

  j.abandonID = this.abandonID;

  return j;
};

