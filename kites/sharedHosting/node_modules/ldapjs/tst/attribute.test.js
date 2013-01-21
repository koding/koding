// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var test = require('tap').test;

var asn1 = require('asn1');


///--- Globals

var BerReader = asn1.BerReader;
var BerWriter = asn1.BerWriter;
var Attribute;


///--- Tests

test('load library', function(t) {
  Attribute = require('../lib/index').Attribute;
  t.ok(Attribute);
  t.end();
});


test('new no args', function(t) {
  t.ok(new Attribute());
  t.end();
});


test('new with args', function(t) {
  var attr = new Attribute({
    type: 'cn',
    vals: ['foo', 'bar']
  });
  t.ok(attr);
  attr.addValue('baz');
  t.equal(attr.type, 'cn');
  t.equal(attr.vals.length, 3);
  t.equal(attr.vals[0], 'foo');
  t.equal(attr.vals[1], 'bar');
  t.equal(attr.vals[2], 'baz');
  t.end();
});


test('toBer', function(t) {
  var attr = new Attribute({
    type: 'cn',
    vals: ['foo', 'bar']
  });
  t.ok(attr);
  var ber = new BerWriter();
  attr.toBer(ber);
  var reader = new BerReader(ber.buffer);
  t.ok(reader.readSequence());
  t.equal(reader.readString(), 'cn');
  t.equal(reader.readSequence(), 0x31); // lber set
  t.equal(reader.readString(), 'foo');
  t.equal(reader.readString(), 'bar');
  t.end();
});


test('parse', function(t) {
  var ber = new BerWriter();
  ber.startSequence();
  ber.writeString('cn');
  ber.startSequence(0x31);
  ber.writeStringArray(['foo', 'bar']);
  ber.endSequence();
  ber.endSequence();

  var attr = new Attribute();
  t.ok(attr);
  t.ok(attr.parse(new BerReader(ber.buffer)));

  t.equal(attr.type, 'cn');
  t.equal(attr.vals.length, 2);
  t.equal(attr.vals[0], 'foo');
  t.equal(attr.vals[1], 'bar');
  t.end();
});
