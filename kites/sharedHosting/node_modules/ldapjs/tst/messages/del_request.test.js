// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var test = require('tap').test;

var asn1 = require('asn1');


///--- Globals

var BerReader = asn1.BerReader;
var BerWriter = asn1.BerWriter;
var DeleteRequest;
var dn;


///--- Tests

test('load library', function(t) {
  DeleteRequest = require('../../lib/index').DeleteRequest;
  dn = require('../../lib/index').dn;
  t.ok(DeleteRequest);
  t.end();
});


test('new no args', function(t) {
  t.ok(new DeleteRequest());
  t.end();
});


test('new with args', function(t) {
  var req = new DeleteRequest({
    entry: dn.parse('cn=test')
  });
  t.ok(req);
  t.equal(req.dn.toString(), 'cn=test');
  t.end();
});


test('parse', function(t) {
  var ber = new BerWriter();
  ber.writeString('cn=test', 0x4a);

  var req = new DeleteRequest();
  var reader = new BerReader(ber.buffer);
  reader.readSequence(0x4a);
  t.ok(req.parse(reader, reader.length));
  t.equal(req.dn.toString(), 'cn=test');
  t.end();
});


test('toBer', function(t) {
  var req = new DeleteRequest({
    messageID: 123,
    entry: dn.parse('cn=test')
  });
  t.ok(req);

  var ber = new BerReader(req.toBer());
  t.ok(ber);
  t.equal(ber.readSequence(), 0x30);
  t.equal(ber.readInt(), 123);
  t.equal(ber.readString(0x4a), 'cn=test');

  t.end();
});
