// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var test = require('tap').test;

var asn1 = require('asn1');


///--- Globals

var BerReader = asn1.BerReader;
var BerWriter = asn1.BerWriter;
var ModifyRequest;
var Attribute;
var Change;
var dn;

///--- Tests

test('load library', function(t) {
  ModifyRequest = require('../../lib/index').ModifyRequest;
  Attribute = require('../../lib/index').Attribute;
  Change = require('../../lib/index').Change;
  dn = require('../../lib/index').dn;
  t.ok(ModifyRequest);
  t.ok(Attribute);
  t.ok(Change);
  t.ok(dn);
  t.end();
});


test('new no args', function(t) {
  t.ok(new ModifyRequest());
  t.end();
});


test('new with args', function(t) {
  var req = new ModifyRequest({
    object: dn.parse('cn=foo, o=test'),
    changes: [new Change({
      operation: 'Replace',
      modification: new Attribute({type: 'objectclass', vals: ['person']})
    })]
  });
  t.ok(req);
  t.equal(req.dn.toString(), 'cn=foo, o=test');
  t.equal(req.changes.length, 1);
  t.equal(req.changes[0].operation, 'replace');
  t.equal(req.changes[0].modification.type, 'objectclass');
  t.equal(req.changes[0].modification.vals[0], 'person');
  t.end();
});


test('parse', function(t) {
  var ber = new BerWriter();
  ber.writeString('cn=foo,o=test');
  ber.startSequence();

  ber.startSequence();
  ber.writeEnumeration(0x02);

  ber.startSequence();
  ber.writeString('objectclass');
  ber.startSequence(0x31);
  ber.writeString('person');
  ber.endSequence();
  ber.endSequence();

  ber.endSequence();

  ber.endSequence();

  var req = new ModifyRequest();
  t.ok(req._parse(new BerReader(ber.buffer)));
  t.equal(req.dn.toString(), 'cn=foo, o=test');
  t.equal(req.changes.length, 1);
  t.equal(req.changes[0].operation, 'replace');
  t.equal(req.changes[0].modification.type, 'objectclass');
  t.equal(req.changes[0].modification.vals[0], 'person');
  t.end();
});


test('toBer', function(t) {
  var req = new ModifyRequest({
    messageID: 123,
    object: dn.parse('cn=foo, o=test'),
    changes: [new Change({
      operation: 'Replace',
      modification: new Attribute({type: 'objectclass', vals: ['person']})
    })]
  });

  t.ok(req);

  var ber = new BerReader(req.toBer());
  t.ok(ber);
  t.equal(ber.readSequence(), 0x30);
  t.equal(ber.readInt(), 123);
  t.equal(ber.readSequence(), 0x66);
  t.equal(ber.readString(), 'cn=foo, o=test');
  t.ok(ber.readSequence());
  t.ok(ber.readSequence());
  t.equal(ber.readEnumeration(), 0x02);

  t.ok(ber.readSequence());
  t.equal(ber.readString(), 'objectclass');
  t.equal(ber.readSequence(), 0x31);
  t.equal(ber.readString(), 'person');

  t.end();
});
