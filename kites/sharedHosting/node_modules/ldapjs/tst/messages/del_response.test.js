// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var test = require('tap').test;

var asn1 = require('asn1');


///--- Globals

var BerReader = asn1.BerReader;
var BerWriter = asn1.BerWriter;
var DeleteResponse;


///--- Tests

test('load library', function(t) {
  DeleteResponse = require('../../lib/index').DeleteResponse;
  t.ok(DeleteResponse);
  t.end();
});


test('new no args', function(t) {
  t.ok(new DeleteResponse());
  t.end();
});


test('new with args', function(t) {
  var res = new DeleteResponse({
    messageID: 123,
    status: 0
  });
  t.ok(res);
  t.equal(res.messageID, 123);
  t.equal(res.status, 0);
  t.end();
});


test('parse', function(t) {
  var ber = new BerWriter();
  ber.writeEnumeration(0);
  ber.writeString('cn=root');
  ber.writeString('foo');

  var res = new DeleteResponse();
  t.ok(res._parse(new BerReader(ber.buffer)));
  t.equal(res.status, 0);
  t.equal(res.matchedDN, 'cn=root');
  t.equal(res.errorMessage, 'foo');
  t.end();
});


test('toBer', function(t) {
  var res = new DeleteResponse({
    messageID: 123,
    status: 3,
    matchedDN: 'cn=root',
    errorMessage: 'foo'
  });
  t.ok(res);

  var ber = new BerReader(res.toBer());
  t.ok(ber);
  t.equal(ber.readSequence(), 0x30);
  t.equal(ber.readInt(), 123);
  t.equal(ber.readSequence(), 0x6b);
  t.equal(ber.readEnumeration(), 3);
  t.equal(ber.readString(), 'cn=root');
  t.equal(ber.readString(), 'foo');

  t.end();
});
