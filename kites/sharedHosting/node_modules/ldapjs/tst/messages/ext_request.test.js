// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var test = require('tap').test;

var asn1 = require('asn1');


///--- Globals

var BerReader = asn1.BerReader;
var BerWriter = asn1.BerWriter;
var ExtendedRequest;
var dn;

///--- Tests

test('load library', function(t) {
  ExtendedRequest = require('../../lib/index').ExtendedRequest;
  dn = require('../../lib/index').dn;
  t.ok(ExtendedRequest);
  t.ok(dn);
  t.end();
});


test('new no args', function(t) {
  t.ok(new ExtendedRequest());
  t.end();
});


test('new with args', function(t) {
  var req = new ExtendedRequest({
    requestName: '1.2.3.4',
    requestValue: 'test'
  });
  t.ok(req);
  t.equal(req.requestName, '1.2.3.4');
  t.equal(req.requestValue, 'test');
  t.end();
});


test('parse', function(t) {
  var ber = new BerWriter();
  ber.writeString('1.2.3.4', 0x80);
  ber.writeString('test', 0x81);


  var req = new ExtendedRequest();
  t.ok(req._parse(new BerReader(ber.buffer)));
  t.equal(req.requestName, '1.2.3.4');
  t.equal(req.requestValue, 'test');
  t.end();
});


test('toBer', function(t) {
  var req = new ExtendedRequest({
    messageID: 123,
    requestName: '1.2.3.4',
    requestValue: 'test'
  });

  t.ok(req);

  var ber = new BerReader(req.toBer());
  t.ok(ber);
  t.equal(ber.readSequence(), 0x30);
  t.equal(ber.readInt(), 123);
  t.equal(ber.readSequence(), 0x77);
  t.equal(ber.readString(0x80), '1.2.3.4');
  t.equal(ber.readString(0x81), 'test');

  t.end();
});
