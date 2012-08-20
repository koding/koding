// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var util = require('util');

var Filter = require('./filter');

var Protocol = require('../protocol');


///--- API

function PresenceFilter(options) {
  if (typeof(options) === 'object') {
    if (!options.attribute || typeof(options.attribute) !== 'string')
      throw new TypeError('options.attribute (string) required');
    this.attribute = options.attribute;
  } else {
    options = {};
  }
  options.type = Protocol.FILTER_PRESENT;
  Filter.call(this, options);

  var self = this;
  this.__defineGetter__('json', function() {
    return {
      type: 'PresenceMatch',
      attribute: self.attribute || undefined
    };
  });
}
util.inherits(PresenceFilter, Filter);
module.exports = PresenceFilter;


PresenceFilter.prototype.toString = function() {
  return '(' + this.attribute + '=*)';
};


PresenceFilter.prototype.matches = function(target) {
  if (typeof(target) !== 'object')
    throw new TypeError('target (object) required');

  return target.hasOwnProperty(this.attribute);
};


PresenceFilter.prototype.parse = function(ber) {
  assert.ok(ber);

  this.attribute =
    ber.buffer.slice(0, ber.length).toString('utf8').toLowerCase();

  ber._offset += ber.length;

  return true;
};


PresenceFilter.prototype._toBer = function(ber) {
  assert.ok(ber);

  for (var i = 0; i < this.attribute.length; i++)
    ber.writeByte(this.attribute.charCodeAt(i));

  return ber;
};
