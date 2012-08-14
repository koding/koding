// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var test = require('tap').test;

var asn1 = require('asn1');


///--- Globals

var SubstringFilter;
var BerReader = asn1.BerReader;
var BerWriter = asn1.BerWriter;



///--- Tests

test('load library', function(t) {
  var filters = require('../../lib/index').filters;
  t.ok(filters);
  SubstringFilter = filters.SubstringFilter;
  t.ok(SubstringFilter);
  t.end();
});


test('Construct no args', function(t) {
  var f = new SubstringFilter();
  t.ok(f);
  t.ok(!f.attribute);
  t.ok(!f.value);
  t.end();
});


test('Construct args', function(t) {
  var f = new SubstringFilter({
    attribute: 'foo',
    initial: 'bar',
    any: ['zig', 'zag'],
    'final': 'baz'
  });
  t.ok(f);
  t.equal(f.attribute, 'foo');
  t.equal(f.initial, 'bar');
  t.equal(f.any.length, 2);
  t.equal(f.any[0], 'zig');
  t.equal(f.any[1], 'zag');
  t.equal(f['final'], 'baz');
  t.equal(f.toString(), '(foo=bar*zig*zag*baz)');
  t.end();
});


test('match true', function(t) {
  var f = new SubstringFilter({
    attribute: 'foo',
    initial: 'bar',
    any: ['zig', 'zag'],
    'final': 'baz'
  });
  t.ok(f);
  t.ok(f.matches({ foo: 'barmoozigbarzagblahbaz' }));
  t.end();
});


test('match false', function(t) {
  var f = new SubstringFilter({
    attribute: 'foo',
    initial: 'bar',
    foo: ['zig', 'zag'],
    'final': 'baz'
  });
  t.ok(f);
  t.ok(!f.matches({ foo: 'bafmoozigbarzagblahbaz' }));
  t.end();
});


test('match any', function(t) {
  var f = new SubstringFilter({
    attribute: 'foo',
    initial: 'bar'
  });
  t.ok(f);
  t.ok(f.matches({ foo: ['beuha', 'barista']}));
  t.end();
});

test('parse ok', function(t) {
  var writer = new BerWriter();
  writer.writeString('foo');
  writer.startSequence();
  writer.writeString('bar', 0x80);
  writer.writeString('bad', 0x81);
  writer.writeString('baz', 0x82);
  writer.endSequence();
  var f = new SubstringFilter();
  t.ok(f);
  t.ok(f.parse(new BerReader(writer.buffer)));
  t.ok(f.matches({ foo: 'bargoobadgoobaz' }));
  t.end();
});


test('parse bad', function(t) {
  var writer = new BerWriter();
  writer.writeString('foo');
  writer.writeInt(20);

  var f = new SubstringFilter();
  t.ok(f);
  try {
    f.parse(new BerReader(writer.buffer));
    t.fail('Should have thrown InvalidAsn1Error');
  } catch (e) {
  }
  t.end();
});
