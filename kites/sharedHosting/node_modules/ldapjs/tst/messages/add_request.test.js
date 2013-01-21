// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var test = require('tap').test;

var asn1 = require('asn1');


///--- Globals

var BerReader = asn1.BerReader;
var BerWriter = asn1.BerWriter;
var AddRequest;
var Attribute;
var dn;

///--- Tests

test('load library', function(t) {
  AddRequest = require('../../lib/index').AddRequest;
  Attribute = require('../../lib/index').Attribute;
  dn = require('../../lib/index').dn;
  t.ok(AddRequest);
  t.ok(Attribute);
  t.ok(dn);
  t.end();
});


test('new no args', function(t) {
  t.ok(new AddRequest());
  t.end();
});


test('new with args', function(t) {
  var req = new AddRequest({
    entry: dn.parse('cn=foo, o=test'),
    attributes: [new Attribute({type: 'cn', vals: ['foo']}),
                 new Attribute({type: 'objectclass', vals: ['person']})]
  });
  t.ok(req);
  t.equal(req.dn.toString(), 'cn=foo, o=test');
  t.equal(req.attributes.length, 2);
  t.equal(req.attributes[0].type, 'cn');
  t.equal(req.attributes[0].vals[0], 'foo');
  t.equal(req.attributes[1].type, 'objectclass');
  t.equal(req.attributes[1].vals[0], 'person');
  t.end();
});


test('parse', function(t) {
  var ber = new BerWriter();
  ber.writeString('cn=foo,o=test');

  ber.startSequence();

  ber.startSequence();
  ber.writeString('cn');
  ber.startSequence(0x31);
  ber.writeString('foo');
  ber.endSequence();
  ber.endSequence();

  ber.startSequence();
  ber.writeString('objectclass');
  ber.startSequence(0x31);
  ber.writeString('person');
  ber.endSequence();
  ber.endSequence();

  ber.endSequence();

  var req = new AddRequest();
  t.ok(req._parse(new BerReader(ber.buffer)));
  t.equal(req.dn.toString(), 'cn=foo, o=test');
  t.equal(req.attributes.length, 2);
  t.equal(req.attributes[0].type, 'cn');
  t.equal(req.attributes[0].vals[0], 'foo');
  t.equal(req.attributes[1].type, 'objectclass');
  t.equal(req.attributes[1].vals[0], 'person');
  t.end();
});


test('toBer', function(t) {
  var req = new AddRequest({
    messageID: 123,
    entry: dn.parse('cn=foo, o=test'),
    attributes: [new Attribute({type: 'cn', vals: ['foo']}),
                 new Attribute({type: 'objectclass', vals: ['person']})]
  });

  t.ok(req);

  var ber = new BerReader(req.toBer());
  t.ok(ber);
  t.equal(ber.readSequence(), 0x30);
  t.equal(ber.readInt(), 123);
  t.equal(ber.readSequence(), 0x68);
  t.equal(ber.readString(), 'cn=foo, o=test');
  t.ok(ber.readSequence());

  t.ok(ber.readSequence());
  t.equal(ber.readString(), 'cn');
  t.equal(ber.readSequence(), 0x31);
  t.equal(ber.readString(), 'foo');

  t.ok(ber.readSequence());
  t.equal(ber.readString(), 'objectclass');
  t.equal(ber.readSequence(), 0x31);
  t.equal(ber.readString(), 'person');

  t.end();
});


test('toObject', function(t) {
  var req = new AddRequest({
    entry: dn.parse('cn=foo, o=test'),
    attributes: [new Attribute({type: 'cn', vals: ['foo', 'bar']}),
                 new Attribute({type: 'objectclass', vals: ['person']})]
  });

  t.ok(req);

  var obj = req.toObject();
  t.ok(obj);

  t.ok(obj.dn);
  t.equal(obj.dn, 'cn=foo, o=test');
  t.ok(obj.attributes);
  t.ok(obj.attributes.cn);
  t.ok(Array.isArray(obj.attributes.cn));
  t.equal(obj.attributes.cn.length, 2);
  t.equal(obj.attributes.cn[0], 'foo');
  t.equal(obj.attributes.cn[1], 'bar');
  t.ok(obj.attributes.objectclass);
  t.ok(Array.isArray(obj.attributes.objectclass));
  t.equal(obj.attributes.objectclass.length, 1);
  t.equal(obj.attributes.objectclass[0], 'person');

  t.end();
});
