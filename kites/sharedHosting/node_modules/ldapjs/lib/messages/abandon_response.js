// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var util = require('util');

var LDAPMessage = require('./result');
var Protocol = require('../protocol');


///--- API
// Stub this out

function AbandonResponse(options) {
  if (!options)
    options = {};
  if (typeof(options) !== 'object')
    throw new TypeError('options must be an object');

  options.protocolOp = 0;
  LDAPMessage.call(this, options);
  this.__defineGetter__('type', function() { return 'AbandonResponse'; });
}
util.inherits(AbandonResponse, LDAPMessage);
module.exports = AbandonResponse;


AbandonResponse.prototype.end = function(status) {};


AbandonResponse.prototype._json = function(j) {
  return j;
};
