// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var test = require('tap').test;

var asn1 = require('asn1');


///--- Globals

var BerReader = asn1.BerReader;
var BerWriter = asn1.BerWriter;
var UnbindRequest;


///--- Tests

test('load library', function(t) {
  UnbindRequest = require('../../lib/index').UnbindRequest;
  t.ok(UnbindRequest);
  t.end();
});


test('new no args', function(t) {
  t.ok(new UnbindRequest());
  t.end();
});


test('new with args', function(t) {
  var req = new UnbindRequest({});
  t.ok(req);
  t.end();
});


test('parse', function(t) {
  var ber = new BerWriter();

  var req = new UnbindRequest();
  t.ok(req._parse(new BerReader(ber.buffer)));
  t.end();
});


test('toBer', function(t) {
  var req = new UnbindRequest({
    messageID: 123
  });
  t.ok(req);

  var ber = new BerReader(req.toBer());
  t.ok(ber);
  t.equal(ber.readSequence(), 0x30);
  t.equal(ber.readInt(), 123);
  t.end();
});
