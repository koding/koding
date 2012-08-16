// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var util = require('util');

var Filter = require('./filter');

var Protocol = require('../protocol');



///--- API

function SubstringFilter(options) {
  if (typeof(options) === 'object') {
    if (!options.attribute || typeof(options.attribute) !== 'string')
      throw new TypeError('options.attribute (string) required');
    this.attribute = options.attribute;
    this.initial = options.initial || null;
    this.any = options.any ? options.any.slice(0) : [];
    this['final'] = options['final'] || null;
  } else {
    options = {};
  }

  if (!this.any)
    this.any = [];

  options.type = Protocol.FILTER_SUBSTRINGS;
  Filter.call(this, options);

  var self = this;
  this.__defineGetter__('json', function() {
    return {
      type: 'SubstringMatch',
      initial: self.initial || undefined,
      any: self.any || undefined,
      'final': self['final'] || undefined
    };
  });
}
util.inherits(SubstringFilter, Filter);
module.exports = SubstringFilter;


SubstringFilter.prototype.toString = function() {
  var str = '(' + this.attribute + '=';

  if (this.initial)
    str += this.initial;

  str += '*';

  this.any.forEach(function(s) {
    str += s + '*';
  });

  if (this['final'])
    str += this['final'];

  str += ')';

  return str;
};


SubstringFilter.prototype.matches = function(target) {
  if (typeof(target) !== 'object')
    throw new TypeError('target (object) required');

  if (target.hasOwnProperty(this.attribute)) {
    var re = '';
    if (this.initial)
      re += '^' + this.initial + '.*';

    this.any.forEach(function(s) {
      re += s + '.*';
    });

    if (this['final'])
      re += this['final'] + '$';

    var matcher = new RegExp(re);
    return Filter.multi_test(
      function(v) { return matcher.test(v); },
      target[this.attribute]);
  }

  return false;
};


SubstringFilter.prototype.parse = function(ber) {
  assert.ok(ber);

  this.attribute = ber.readString().toLowerCase();
  ber.readSequence();
  var end = ber.offset + ber.length;

  while (ber.offset < end) {
    var tag = ber.peek();
    switch (tag) {
    case 0x80: // Initial
      this.initial = ber.readString(tag);
      if (this.attribute === 'objectclass')
        this.initial = this.initial.toLowerCase();
      break;
    case 0x81: // Any
      var anyVal = ber.readString(tag);
      if (this.attribute === 'objectclass')
        anyVal = anyVal.toLowerCase();
      this.any.push(anyVal);
      break;
    case 0x82: // Final
      this['final'] = ber.readString(tag);
      if (this.attribute === 'objectclass')
        this['final'] = this['final'].toLowerCase();
      break;
    default:
      throw new Error('Invalid substrings filter type: 0x' + tag.toString(16));
    }
  }

  return true;
};


SubstringFilter.prototype._toBer = function(ber) {
  assert.ok(ber);

  ber.writeString(this.attribute);
  ber.startSequence();

  if (this.initial)
    ber.writeString(this.initial, 0x80);

  if (this.any && this.any.length)
    this.any.forEach(function(s) {
      ber.writeString(s, 0x81);
    });

  if (this['final'])
    ber.writeString(this['final'], 0x82);

  ber.endSequence();

  return ber;
};
