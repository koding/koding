// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var test = require('tap').test;

var asn1 = require('asn1');


///--- Globals

var BerReader = asn1.BerReader;
var BerWriter = asn1.BerWriter;
var SearchRequest;
var EqualityFilter;
var dn;

///--- Tests

test('load library', function(t) {
  SearchRequest = require('../../lib/index').SearchRequest;
  EqualityFilter = require('../../lib/index').EqualityFilter;
  dn = require('../../lib/index').dn;
  t.ok(SearchRequest);
  t.ok(EqualityFilter);
  t.ok(dn);
  t.end();
});


test('new no args', function(t) {
  t.ok(new SearchRequest());
  t.end();
});


test('new with args', function(t) {
  var req = new SearchRequest({
    baseObject: dn.parse('cn=foo, o=test'),
    filter: new EqualityFilter({
      attribute: 'email',
      value: 'foo@bar.com'
    }),
    attributes: ['cn', 'sn']
  });
  t.ok(req);
  t.equal(req.dn.toString(), 'cn=foo, o=test');
  t.equal(req.filter.toString(), '(email=foo@bar.com)');
  t.equal(req.attributes.length, 2);
  t.equal(req.attributes[0], 'cn');
  t.equal(req.attributes[1], 'sn');
  t.end();
});


test('parse', function(t) {
  var f = new EqualityFilter({
    attribute: 'email',
    value: 'foo@bar.com'
  });

  var ber = new BerWriter();
  ber.writeString('cn=foo,o=test');
  ber.writeEnumeration(0);
  ber.writeEnumeration(0);
  ber.writeInt(1);
  ber.writeInt(2);
  ber.writeBoolean(false);
  ber = f.toBer(ber);

  var req = new SearchRequest();
  t.ok(req._parse(new BerReader(ber.buffer)));
  t.equal(req.dn.toString(), 'cn=foo, o=test');
  t.equal(req.scope, 'base');
  t.equal(req.derefAliases, 0);
  t.equal(req.sizeLimit, 1);
  t.equal(req.timeLimit, 2);
  t.equal(req.typesOnly, false);
  t.equal(req.filter.toString(), '(email=foo@bar.com)');
  t.equal(req.attributes.length, 0);
  t.end();
});


test('toBer', function(t) {
  var req = new SearchRequest({
    messageID: 123,
    baseObject: dn.parse('cn=foo, o=test'),
    scope: 1,
    derefAliases: 2,
    sizeLimit: 10,
    timeLimit: 20,
    typesOnly: true,
    filter: new EqualityFilter({
      attribute: 'email',
      value: 'foo@bar.com'
    }),
    attributes: ['cn', 'sn']
  });

  t.ok(req);

  var ber = new BerReader(req.toBer());
  t.ok(ber);
  t.equal(ber.readSequence(), 0x30);
  t.equal(ber.readInt(), 123);
  t.equal(ber.readSequence(), 0x63);
  t.equal(ber.readString(), 'cn=foo, o=test');
  t.equal(ber.readEnumeration(), 1);
  t.equal(ber.readEnumeration(), 2);
  t.equal(ber.readInt(), 10);
  t.equal(ber.readInt(), 20);
  t.ok(ber.readBoolean());
  t.equal(ber.readSequence(), 0xa3);
  t.equal(ber.readString(), 'email');
  t.equal(ber.readString(), 'foo@bar.com');
  t.ok(ber.readSequence());
  t.equal(ber.readString(), 'cn');
  t.equal(ber.readString(), 'sn');

  t.end();
});
