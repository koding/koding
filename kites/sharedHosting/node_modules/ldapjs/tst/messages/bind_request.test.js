// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var test = require('tap').test;

var asn1 = require('asn1');


///--- Globals

var BerReader = asn1.BerReader;
var BerWriter = asn1.BerWriter;
var BindRequest;
var dn;

///--- Tests

test('load library', function(t) {
  BindRequest = require('../../lib/index').BindRequest;
  dn = require('../../lib/index').dn;
  t.ok(BindRequest);
  t.ok(dn);
  t.end();
});


test('new no args', function(t) {
  t.ok(new BindRequest());
  t.end();
});


test('new with args', function(t) {
  var req = new BindRequest({
    version: 3,
    name: dn.parse('cn=root'),
    credentials: 'secret'
  });
  t.ok(req);
  t.equal(req.version, 3);
  t.equal(req.name.toString(), 'cn=root');
  t.equal(req.credentials, 'secret');
  t.end();
});


test('parse', function(t) {
  var ber = new BerWriter();
  ber.writeInt(3);
  ber.writeString('cn=root');
  ber.writeString('secret', 0x80);

  var req = new BindRequest();
  t.ok(req._parse(new BerReader(ber.buffer)));
  t.equal(req.version, 3);
  t.equal(req.dn.toString(), 'cn=root');
  t.ok(req.name.constructor);
  t.equal(req.name.constructor.name, 'DN');
  t.equal(req.credentials, 'secret');
  t.end();
});


test('toBer', function(t) {
  var req = new BindRequest({
    messageID: 123,
    version: 3,
    name: dn.parse('cn=root'),
    credentials: 'secret'
  });
  t.ok(req);

  var ber = new BerReader(req.toBer());
  t.ok(ber);
  t.equal(ber.readSequence(), 0x30);
  t.equal(ber.readInt(), 123);
  t.equal(ber.readSequence(), 0x60);
  t.equal(ber.readInt(), 0x03);
  t.equal(ber.readString(), 'cn=root');
  t.equal(ber.readString(0x80), 'secret');

  t.end();
});
