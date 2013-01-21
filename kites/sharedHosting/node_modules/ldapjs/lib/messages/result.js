// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var util = require('util');

var asn1 = require('asn1');

var dtrace = require('../dtrace');
var LDAPMessage = require('./message');
var Protocol = require('../protocol');



///--- Globals

var Ber = asn1.Ber;
var BerWriter = asn1.BerWriter;



///--- API

function LDAPResult(options) {
  if (options) {
    if (typeof(options) !== 'object')
      throw new TypeError('options (object) required');
    if (options.status && typeof(options.status) !== 'number')
      throw new TypeError('options.status must be a number');
    if (options.matchedDN && typeof(options.matchedDN) !== 'string')
      throw new TypeError('options.matchedDN must be a string');
    if (options.errorMessage && typeof(options.errorMessage) !== 'string')
      throw new TypeError('options.errorMessage must be a string');

    if (options.referrals) {
      if (!(options.referrals instanceof Array))
        throw new TypeError('options.referrrals must be an array[string]');
      options.referrals.forEach(function(r) {
        if (typeof(r) !== 'string')
          throw new TypeError('options.referrals must be an array[string]');
      });
    }
  } else {
    options = {};
  }

  LDAPMessage.call(this, options);

  this.status = options.status || 0; // LDAP SUCCESS
  this.matchedDN = options.matchedDN || '';
  this.errorMessage = options.errorMessage || '';
  this.referrals = options.referrals || [];

  this.connection = options.connection || null;

  this.__defineGetter__('type', function() { return 'LDAPResult'; });
}
util.inherits(LDAPResult, LDAPMessage);
module.exports = LDAPResult;


LDAPResult.prototype.end = function(status) {
  assert.ok(this.connection);

  if (typeof(status) === 'number')
    this.status = status;

  var ber = this.toBer();
  if (this.log.isDebugEnabled())
    this.log.debug('%s: sending:  %j', this.connection.ldap.id, this.json);

  try {
    var self = this;
    this.connection.write(ber);

    if (self._dtraceOp && self._dtraceId) {
      dtrace.fire('server-' + self._dtraceOp + '-done', function() {
        var c = self.connection || {ldap: {}};
        return [
          self._dtraceId || 0,
          (c.remoteAddress || ''),
          c.ldap.bindDN ? c.ldap.bindDN.toString() : '',
          (self.requestDN ? self.requestDN.toString() : ''),
          status || self.status,
          self.errorMessage
        ];
      });
    }

  } catch (e) {
    this.log.warn('%s failure to write message %j: %s',
                  this.connection.ldap.id, this.json, e.toString());
  }

};


LDAPResult.prototype._parse = function(ber) {
  assert.ok(ber);

  this.status = ber.readEnumeration();
  this.matchedDN = ber.readString();
  this.errorMessage = ber.readString();

  var t = ber.peek();

  if (t === Protocol.LDAP_REP_REFERRAL) {
    var end = ber.offset + ber.length;
    while (ber.offset < end)
      this.referrals.push(ber.readString());
  }

  return true;
};


LDAPResult.prototype._toBer = function(ber) {
  assert.ok(ber);

  ber.writeEnumeration(this.status);
  ber.writeString(this.matchedDN || '');
  ber.writeString(this.errorMessage || '');

  if (this.referrals.length) {
    ber.startSequence(Protocol.LDAP_REP_REFERRAL);
    ber.writeStringArray(this.referrals);
    ber.endSequence();
  }

  return ber;
};


LDAPResult.prototype._json = function(j) {
  assert.ok(j);

  j.status = this.status;
  j.matchedDN = this.matchedDN;
  j.errorMessage = this.errorMessage;
  j.referrals = this.referrals;

  return j;
};
