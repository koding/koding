// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var util = require('util');

var asn1 = require('asn1');

var LDAPMessage = require('./message');
var Protocol = require('../protocol');
var dn = require('../dn');
var url = require('../url');



///--- Globals

var BerWriter = asn1.BerWriter;
var parseURL = url.parse;



///--- API

function SearchReference(options) {
  if (options) {
    if (typeof(options) !== 'object')
      throw new TypeError('options must be an object');
    if (options.objectName && !(options.objectName instanceof dn.DN))
      throw new TypeError('options.objectName must be a DN');
  } else {
    options = {};
  }

  options.protocolOp = Protocol.LDAP_REP_SEARCH_REF;
  LDAPMessage.call(this, options);

  this.uris = options.uris || [];

  var self = this;
  this.__defineGetter__('type', function() { return 'SearchReference'; });
  this.__defineGetter__('object', function() {
    return {
      dn: self.dn.toString(),
      uris: self.uris.slice()
    };
  });
  this.__defineGetter__('_dn', function() {
    return new dn.DN('');
  });
  this.__defineGetter__('urls', function() {
    return self.uris;
  });
  this.__defineSetter__('urls', function(u) {
    self.uris = u.slice();
  });
}
util.inherits(SearchReference, LDAPMessage);
module.exports = SearchReference;


SearchReference.prototype.toObject = function() {
  return this.object;
};


SearchReference.prototype.fromObject = function(obj) {
  if (typeof(obj) !== 'object')
    throw new TypeError('object required');

  this.uris = obj.uris ? obj.uris.slice() : [];

  return true;
};

SearchReference.prototype._json = function(j) {
  assert.ok(j);
  j.uris = this.uris.slice();
  return j;
};


SearchReference.prototype._parse = function(ber, length) {
  assert.ok(ber);

  while (ber.offset < length) {
    var _url = ber.readString();
    parseURL(_url);
    this.uris.push(_url);
  }

  return true;
};


SearchReference.prototype._toBer = function(ber) {
  assert.ok(ber);

  this.uris.forEach(function(u) {
    ber.writeString(u.href || u);
  });

  return ber;
};



