// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var util = require('util');

var asn1 = require('asn1');

var Control = require('../controls').Control;
var Protocol = require('../protocol');

var logStub = require('../log_stub');



///--- Globals

var Ber = asn1.Ber;
var BerReader = asn1.BerReader;
var BerWriter = asn1.BerWriter;
var getControl = require('../controls').getControl;



///--- API


/**
 * LDAPMessage structure.
 *
 * @param {Object} options stuff.
 */
function LDAPMessage(options) {
  if (!options || typeof(options) !== 'object')
    throw new TypeError('options (object) required');

  this.messageID = options.messageID || 0;
  this.protocolOp = options.protocolOp || undefined;
  this.controls = options.controls ? options.controls.slice(0) : [];

  this.log4js = options.log4js || logStub;

  var self = this;
  this.__defineGetter__('id', function() { return self.messageID; });
  this.__defineGetter__('dn', function() { return self._dn || ''; });
  this.__defineGetter__('type', function() { return 'LDAPMessage'; });
  this.__defineGetter__('json', function() {
    var j = {
      messageID: self.messageID,
      protocolOp: self.type
    };
    j = self._json(j);
    j.controls = self.controls;
    return j;
  });
  this.__defineGetter__('log', function() {
    if (!self._log)
      self._log = self.log4js.getLogger(self.type);
    return self._log;
  });
}
module.exports = LDAPMessage;


LDAPMessage.prototype.toString = function() {
  return JSON.stringify(this.json);
};


LDAPMessage.prototype.parse = function(ber) {
  assert.ok(ber);

  if (this.log.isTraceEnabled())
    this.log.trace('parse: data=%s', util.inspect(ber.buffer));

  // Delegate off to the specific type to parse
  this._parse(ber, ber.remain);

  // Look for controls
  if (ber.peek() === 0xa0) {
    ber.readSequence();
    var end = ber.offset + ber.length;
    while (ber.offset < end) {
      var c = getControl(ber);
      if (c)
        this.controls.push(c);
    }
  }

  if (this.log.isTraceEnabled())
    this.log.trace('Parsing done: %j', this.json);
  return true;
};


LDAPMessage.prototype.toBer = function() {
  var writer = new BerWriter();
  writer.startSequence();
  writer.writeInt(this.messageID);

  writer.startSequence(this.protocolOp);
  if (this._toBer)
    writer = this._toBer(writer);
  writer.endSequence();

  if (this.controls && this.controls.length) {
    writer.startSequence(0xa0);
    this.controls.forEach(function(c) {
      c.toBer(writer);
    });
    writer.endSequence();
  }

  writer.endSequence();
  return writer.buffer;
};
