// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var util = require('util');

var Filter = require('./filter');

var Protocol = require('../protocol');



///--- API

function OrFilter(options) {
  if (typeof(options) === 'object') {
    if (!options.filters || !Array.isArray(options.filters))
      throw new TypeError('options.filters ([Filter]) required');
    this.filters = options.filters.slice();
  } else {
    options = {};
  }

  options.type = Protocol.FILTER_OR;
  Filter.call(this, options);

  if (!this.filters)
    this.filters = [];

  var self = this;
  this.__defineGetter__('json', function() {
    return {
      type: 'Or',
      filters: self.filters || []
    };
  });
}
util.inherits(OrFilter, Filter);
module.exports = OrFilter;


OrFilter.prototype.toString = function() {
  var str = '(|';
  this.filters.forEach(function(f) {
    str += f.toString();
  });
  str += ')';

  return str;
};


OrFilter.prototype.matches = function(target) {
  if (typeof(target) !== 'object')
    throw new TypeError('target (object) required');

  for (var i = 0; i < this.filters.length; i++)
    if (this.filters[i].matches(target))
      return true;

  return false;
};


OrFilter.prototype.addFilter = function(filter) {
  if (!filter || typeof(filter) !== 'object')
    throw new TypeError('filter (object) required');

  this.filters.push(filter);
};


OrFilter.prototype._toBer = function(ber) {
  assert.ok(ber);

  this.filters.forEach(function(f) {
    ber = f.toBer(ber);
  });

  return ber;
};
