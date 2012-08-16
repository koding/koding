// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var test = require('tap').test;

var asn1 = require('asn1');


///--- Globals

var BerReader = asn1.BerReader;
var BerWriter = asn1.BerWriter;
var ExtendedResponse;


///--- Tests

test('load library', function(t) {
  ExtendedResponse = require('../../lib/index').ExtendedResponse;
  t.ok(ExtendedResponse);
  t.end();
});


test('new no args', function(t) {
  t.ok(new ExtendedResponse());
  t.end();
});


test('new with args', function(t) {
  var res = new ExtendedResponse({
    messageID: 123,
    status: 0,
    responseName: '1.2.3.4',
    responseValue: 'test'
  });
  t.ok(res);
  t.equal(res.messageID, 123);
  t.equal(res.status, 0);
  t.equal(res.responseName, '1.2.3.4');
  t.equal(res.responseValue, 'test');
  t.end();
});


test('parse', function(t) {
  var ber = new BerWriter();
  ber.writeEnumeration(0);
  ber.writeString('cn=root');
  ber.writeString('foo');
  ber.writeString('1.2.3.4', 0x8a);
  ber.writeString('test', 0x8b);

  var res = new ExtendedResponse();
  t.ok(res._parse(new BerReader(ber.buffer)));
  t.equal(res.status, 0);
  t.equal(res.matchedDN, 'cn=root');
  t.equal(res.errorMessage, 'foo');
  t.equal(res.responseName, '1.2.3.4');
  t.equal(res.responseValue, 'test');
  t.end();
});


test('toBer', function(t) {
  var res = new ExtendedResponse({
    messageID: 123,
    status: 3,
    matchedDN: 'cn=root',
    errorMessage: 'foo',
    responseName: '1.2.3.4',
    responseValue: 'test'
  });
  t.ok(res);

  var ber = new BerReader(res.toBer());
  t.ok(ber);
  t.equal(ber.readSequence(), 0x30);
  t.equal(ber.readInt(), 123);
  t.equal(ber.readSequence(), 0x78);
  t.equal(ber.readEnumeration(), 3);
  t.equal(ber.readString(), 'cn=root');
  t.equal(ber.readString(), 'foo');
  t.equal(ber.readString(0x8a), '1.2.3.4');
  t.equal(ber.readString(0x8b), 'test');

  t.end();
});
