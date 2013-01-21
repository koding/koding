// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var util = require('util');

var asn1 = require('asn1');

var LDAPMessage = require('./message');
var LDAPResult = require('./result');

var dn = require('../dn');
var filters = require('../filters');
var Protocol = require('../protocol');



///--- Globals

var Ber = asn1.Ber;



///--- API

function SearchRequest(options) {
  if (options) {
    if (typeof(options) !== 'object')
      throw new TypeError('options must be an object');
  } else {
    options = {};
  }

  options.protocolOp = Protocol.LDAP_REQ_SEARCH;
  LDAPMessage.call(this, options);

  var self = this;
  this.__defineGetter__('type', function() { return 'SearchRequest'; });
  this.__defineGetter__('_dn', function() {
    return self.baseObject;
  });
  this.__defineGetter__('scope', function() {
    switch (self._scope) {
    case Protocol.SCOPE_BASE_OBJECT: return 'base';
    case Protocol.SCOPE_ONE_LEVEL: return 'one';
    case Protocol.SCOPE_SUBTREE: return 'sub';
    default:
      throw new Error(self._scope + ' is an invalid search scope');
    }
  });
  this.__defineSetter__('scope', function(s) {
    if (typeof(s) === 'string') {
      switch (s) {
      case 'base':
        self._scope = Protocol.SCOPE_BASE_OBJECT;
        break;
      case 'one':
        self._scope = Protocol.SCOPE_ONE_LEVEL;
        break;
      case 'sub':
        self._scope = Protocol.SCOPE_SUBTREE;
        break;
      default:
        throw new Error(s + ' is an invalid search scope');
      }
    } else {
      self._scope = s;
    }
  });

  this.baseObject = options.baseObject || new dn.DN([{}]);
  this.scope = options.scope || 'base';
  this.derefAliases = options.derefAliases || Protocol.NEVER_DEREF_ALIASES;
  this.sizeLimit = options.sizeLimit || 0;
  this.timeLimit = options.timeLimit || 0;
  this.typesOnly = options.typesOnly || false;
  this.filter = options.filter || null;
  this.attributes = options.attributes ? options.attributes.slice(0) : [];
}
util.inherits(SearchRequest, LDAPMessage);
module.exports = SearchRequest;


SearchRequest.prototype.newResult = function() {
  var self = this;

  return new LDAPResult({
    messageID: self.messageID,
    protocolOp: Protocol.LDAP_REP_SEARCH
  });
};


SearchRequest.prototype._parse = function(ber) {
  assert.ok(ber);

  this.baseObject = dn.parse(ber.readString());
  this.scope = ber.readEnumeration();
  this.derefAliases = ber.readEnumeration();
  this.sizeLimit = ber.readInt();
  this.timeLimit = ber.readInt();
  this.typesOnly = ber.readBoolean();

  this.filter = filters.parse(ber);

  // look for attributes
  if (ber.peek() === 0x30) {
    ber.readSequence();
    var end = ber.offset + ber.length;
    while (ber.offset < end)
      this.attributes.push(ber.readString().toLowerCase());
  }

  return true;
};


SearchRequest.prototype._toBer = function(ber) {
  assert.ok(ber);

  ber.writeString(this.baseObject.toString());
  ber.writeEnumeration(this._scope);
  ber.writeEnumeration(this.derefAliases);
  ber.writeInt(this.sizeLimit);
  ber.writeInt(this.timeLimit);
  ber.writeBoolean(this.typesOnly);

  var f = this.filter || new filters.PresenceFilter({attribute: 'objectclass'});
  ber = f.toBer(ber);

  ber.startSequence(Ber.Sequence | Ber.Constructor);
  if (this.attributes && this.attributes.length) {
    this.attributes.forEach(function(a) {
      ber.writeString(a);
    });
  }
  ber.endSequence();

  return ber;
};


SearchRequest.prototype._json = function(j) {
  assert.ok(j);

  j.baseObject = this.baseObject;
  j.scope = this.scope;
  j.derefAliases = this.derefAliases;
  j.sizeLimit = this.sizeLimit;
  j.timeLimit = this.timeLimit;
  j.typesOnly = this.typesOnly;
  j.filter = this.filter.toString();
  j.attributes = this.attributes;

  return j;
};
