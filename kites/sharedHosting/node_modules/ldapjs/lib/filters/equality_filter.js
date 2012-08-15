// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var util = require('util');

var Filter = require('./filter');

var Protocol = require('../protocol');



///--- API

function EqualityFilter(options) {
  if (typeof(options) === 'object') {
    if (!options.attribute || typeof(options.attribute) !== 'string')
      throw new TypeError('options.attribute (string) required');
    if (!options.value || typeof(options.value) !== 'string')
      throw new TypeError('options.value (string) required');
    this.attribute = options.attribute;
    this.value = options.value;
  } else {
    options = {};
  }
  options.type = Protocol.FILTER_EQUALITY;
  Filter.call(this, options);

  var self = this;
  this.__defineGetter__('json', function() {
    return {
      type: 'EqualityMatch',
      attribute: self.attribute || undefined,
      value: self.value || undefined
    };
  });
}
util.inherits(EqualityFilter, Filter);
module.exports = EqualityFilter;


EqualityFilter.prototype.toString = function() {
  return '(' + this.attribute + '=' + this.value + ')';
};


EqualityFilter.prototype.matches = function(target) {
  if (typeof(target) !== 'object')
    throw new TypeError('target (object) required');

  if (target.hasOwnProperty(this.attribute)) {
    var value = this.value;
    return Filter.multi_test(
      function(v) { return value === v; },
      target[this.attribute]);
  }

  return false;
};


EqualityFilter.prototype.parse = function(ber) {
  assert.ok(ber);

  this.attribute = ber.readString().toLowerCase();
  this.value = ber.readString();

  if (this.attribute === 'objectclass')
    this.value = this.value.toLowerCase();

  return true;
};


EqualityFilter.prototype._toBer = function(ber) {
  assert.ok(ber);

  ber.writeString(this.attribute);
  ber.writeString(this.value);

  return ber;
};
