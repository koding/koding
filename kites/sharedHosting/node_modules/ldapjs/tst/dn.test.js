// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var test = require('tap').test;



///--- Globals

var dn;



///--- Tests

test('load library', function(t) {
  dn = require('../lib/index').dn;
  t.ok(dn);
  t.end();
});


test('parse basic', function(t) {
  var DN_STR = 'cn=mark, ou=people, o=joyent';
  var name = dn.parse(DN_STR);
  t.ok(name);
  t.ok(name.rdns);
  t.ok(Array.isArray(name.rdns));
  t.equal(3, name.rdns.length);
  name.rdns.forEach(function(rdn) {
    t.equal('object', typeof(rdn));
  });
  t.equal(name.toString(), DN_STR);
  t.end();
});


test('parse escaped', function(t) {
  var DN_STR = 'cn=m\\,ark, ou=people, o=joyent';
  var name = dn.parse(DN_STR);
  t.ok(name);
  t.ok(name.rdns);
  t.ok(Array.isArray(name.rdns));
  t.equal(3, name.rdns.length);
  name.rdns.forEach(function(rdn) {
    t.equal('object', typeof(rdn));
  });
  t.equal(name.toString(), DN_STR);
  t.end();
});


test('parse compound', function(t) {
  var DN_STR = 'cn=mark+sn=cavage, ou=people, o=joyent';
  var name = dn.parse(DN_STR);
  t.ok(name);
  t.ok(name.rdns);
  t.ok(Array.isArray(name.rdns));
  t.equal(3, name.rdns.length);
  name.rdns.forEach(function(rdn) {
    t.equal('object', typeof(rdn));
  });
  t.equal(name.toString(), DN_STR);
  t.end();
});


test('parse quoted', function(t) {
  var DN_STR = 'cn="mark+sn=cavage", ou=people, o=joyent';
  var name = dn.parse(DN_STR);
  t.ok(name);
  t.ok(name.rdns);
  t.ok(Array.isArray(name.rdns));
  t.equal(3, name.rdns.length);
  name.rdns.forEach(function(rdn) {
    t.equal('object', typeof(rdn));
  });
  t.equal(name.toString(), DN_STR);
  t.end();
});


test('equals', function(t) {
  var dn1 = dn.parse('cn=foo, dc=bar');
  t.ok(dn1.equals('cn=foo, dc=bar'));
  t.ok(!dn1.equals('cn=foo1, dc=bar'));
  t.ok(dn1.equals(dn.parse('cn=foo, dc=bar')));
  t.ok(!dn1.equals(dn.parse('cn=foo2, dc=bar')));
  t.end();
});


test('child of', function(t) {
  var dn1 = dn.parse('cn=foo, dc=bar');
  t.ok(dn1.childOf('dc=bar'));
  t.ok(!dn1.childOf('dc=moo'));
  t.ok(!dn1.childOf('dc=foo'));
  t.ok(!dn1.childOf('cn=foo, dc=bar'));

  t.ok(dn1.childOf(dn.parse('dc=bar')));
  t.end();
});


test('parent of', function(t) {
  var dn1 = dn.parse('cn=foo, dc=bar');
  t.ok(dn1.parentOf('cn=moo, cn=foo, dc=bar'));
  t.ok(!dn1.parentOf('cn=moo, cn=bar, dc=foo'));
  t.ok(!dn1.parentOf('cn=foo, dc=bar'));

  t.ok(dn1.parentOf(dn.parse('cn=moo, cn=foo, dc=bar')));
  t.end();
});


test('empty DNs GH-16', function(t) {
  var _dn = dn.parse('');
  var _dn2 = dn.parse('cn=foo');
  t.notOk(_dn.equals('cn=foo'));
  t.notOk(_dn2.equals(''));
  t.notOk(_dn.parentOf('cn=foo'));
  t.notOk(_dn.childOf('cn=foo'));
  t.notOk(_dn2.parentOf(''));
  t.notOk(_dn2.childOf(''));
  t.end();
});


test('case insensitive attribute names GH-20', function(t) {
  var dn1 = dn.parse('CN=foo, dc=bar');
  t.ok(dn1.equals('cn=foo, dc=bar'));
  t.ok(dn1.equals(dn.parse('cn=foo, DC=bar')));
  t.end();
});
