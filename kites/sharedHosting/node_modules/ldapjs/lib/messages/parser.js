// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var EventEmitter = require('events').EventEmitter;
var util = require('util');

var asn1 = require('asn1');

var AbandonRequest = require('./abandon_request');
var AddRequest = require('./add_request');
var AddResponse = require('./add_response');
var BindRequest = require('./bind_request');
var BindResponse = require('./bind_response');
var CompareRequest = require('./compare_request');
var CompareResponse = require('./compare_response');
var DeleteRequest = require('./del_request');
var DeleteResponse = require('./del_response');
var ExtendedRequest = require('./ext_request');
var ExtendedResponse = require('./ext_response');
var ModifyRequest = require('./modify_request');
var ModifyResponse = require('./modify_response');
var ModifyDNRequest = require('./moddn_request');
var ModifyDNResponse = require('./moddn_response');
var SearchRequest = require('./search_request');
var SearchEntry = require('./search_entry');
var SearchReference = require('./search_reference');
var SearchResponse = require('./search_response');
var UnbindRequest = require('./unbind_request');
var UnbindResponse = require('./unbind_response');

var LDAPResult = require('./result');
var Message = require('./message');

var Protocol = require('../protocol');

// Just make sure this adds to the prototype
require('buffertools');



///--- Globals

var Ber = asn1.Ber;
var BerReader = asn1.BerReader;



///--- API

function Parser(options) {
  if (!options || typeof(options) !== 'object')
    throw new TypeError('options (object) required');
  if (!options.log4js || typeof(options.log4js) !== 'object')
    throw new TypeError('options.log4js (object) required');

  EventEmitter.call(this);

  this.buffer = null;
  this.log4js = options.log4js;
  this.log = this.log4js.getLogger('Parser');
}
util.inherits(Parser, EventEmitter);
module.exports = Parser;


Parser.prototype.write = function(data) {
  if (!data || !Buffer.isBuffer(data))
    throw new TypeError('data (buffer) required');

  var log = this.log;
  var nextMessage = null;
  var self = this;

  function end() {
    if (nextMessage)
      return self.write(nextMessage);

    return true;
  }

  self.buffer = (self.buffer ? self.buffer.concat(data) : data);

  var ber = new BerReader(self.buffer);
  if (!ber.readSequence())
    return false;

  if (ber.remain < ber.length) { // ENOTENOUGH
    return false;
  } else if (ber.remain > ber.length) { // ETOOMUCH
    // This is sort of ugly, but allows us to make miminal copies
    nextMessage = self.buffer.slice(ber.offset + ber.length);
    ber._size = ber.offset + ber.length;
    assert.equal(ber.remain, ber.length);
  }

  // If we're here, ber holds the message, and nextMessage is temporarily
  // pointing at the next sequence of data (if it exists)
  self.buffer = null;

  var message = this.getMessage(ber);
  if (!message)
    return end();

  try {
    message.parse(ber);
    this.emit('message', message);
  } catch (e) {
    this.emit('error', e, message);
    return false;
  }

  return end();
};


Parser.prototype.getMessage = function(ber) {
  assert.ok(ber);

  var log = this.log;
  var self = this;

  var messageID = ber.readInt();
  var type = ber.readSequence();

  var Message;
  switch (type) {

  case Protocol.LDAP_REQ_ABANDON:
    Message = AbandonRequest;
    break;

  case Protocol.LDAP_REQ_ADD:
    Message = AddRequest;
    break;

  case Protocol.LDAP_REP_ADD:
    Message = AddResponse;
    break;

  case Protocol.LDAP_REQ_BIND:
    Message = BindRequest;
    break;

  case Protocol.LDAP_REP_BIND:
    Message = BindResponse;
    break;

  case Protocol.LDAP_REQ_COMPARE:
    Message = CompareRequest;
    break;

  case Protocol.LDAP_REP_COMPARE:
    Message = CompareResponse;
    break;

  case Protocol.LDAP_REQ_DELETE:
    Message = DeleteRequest;
    break;

  case Protocol.LDAP_REP_DELETE:
    Message = DeleteResponse;
    break;

  case Protocol.LDAP_REQ_EXTENSION:
    Message = ExtendedRequest;
    break;

  case Protocol.LDAP_REP_EXTENSION:
    Message = ExtendedResponse;
    break;

  case Protocol.LDAP_REQ_MODIFY:
    Message = ModifyRequest;
    break;

  case Protocol.LDAP_REP_MODIFY:
    Message = ModifyResponse;
    break;

  case Protocol.LDAP_REQ_MODRDN:
    Message = ModifyDNRequest;
    break;

  case Protocol.LDAP_REP_MODRDN:
    Message = ModifyDNResponse;
    break;

  case Protocol.LDAP_REQ_SEARCH:
    Message = SearchRequest;
    break;

  case Protocol.LDAP_REP_SEARCH_ENTRY:
    Message = SearchEntry;
    break;

  case Protocol.LDAP_REP_SEARCH_REF:
    Message = SearchReference;
    break;

  case Protocol.LDAP_REP_SEARCH:
    Message = SearchResponse;
    break;

  case Protocol.LDAP_REQ_UNBIND:
    Message = UnbindRequest;
    break;

  default:
    this.emit('error',
              new Error('protocolOp 0x' +
                        (type ? type.toString(16) : '??') +
                        ' not supported'
                       ),
              new LDAPResult({
                messageID: messageID,
                protocolOp: type || Protocol.LDAP_REP_EXTENSION
              }));

    return false;
  }


  return new Message({
    messageID: messageID,
    log4js: self.log4js
  });
};

