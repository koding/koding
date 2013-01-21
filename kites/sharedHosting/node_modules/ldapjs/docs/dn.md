---
title: DN API | ldapjs
markdown2extras: wiki-tables
logo-color: green
logo-font-family: google:Aldrich, Verdana, sans-serif
header-font-family: google:Aldrich, Verdana, sans-serif
---

# ldapjs DN API

This document covers the ldapjs DN API and assumes that you are familiar
with LDAP. If you're not, read the [guide](http://ldapjs.org/guide.html) first.

DNs are LDAP distinguished names, and are composed of a set of RDNs (relative
distinguished names).  [RFC2253](http://www.ietf.org/rfc/rfc2253.txt) has the
complete specification, but basically an RDN is an attribute value assertion
with `=` as the seperator, like: `cn=foo` where 'cn' is 'commonName' and 'foo'
is the value.  You can have compound RDNs by using the `+` character:
`cn=foo+sn=bar`.  As stated above, DNs are a set of RDNs, typically separated
with the `,` character, like:  `cn=foo, ou=people, o=example`.  This uniquely
identifies an entry in the tree, and is read "bottom up".

# parseDN(dnString)

The `parseDN` API converts a string representation of a DN into an ldapjs DN
object; in most cases this will be handled for you under the covers of the
ldapjs framework, but if you need it, it's there.

    var parseDN = require('ldapjs').parseDN;

    var dn = parseDN('cn=foo+sn=bar, ou=people, o=example');
    console.log(dn.toString());

# DN

The DN object is largely what you'll be interacting with, since all the server
APIs are setup to give you a DN object.

## childOf(dn)

Returns a boolean indicating whether 'this' is a child of the passed in dn. The
`dn` argument can be either a string or a DN.

    server.add('o=example', function(req, res, next) {
      if (req.dn.childOf('ou=people, o=example')) {
        ...
      } else {
        ...
      }
    });

## parentOf(dn)

The inverse of `childOf`; returns a boolean on whether or not `this` is a parent
of the passed in dn.  Like `childOf`, can take either a string or a DN.

    server.add('o=example', function(req, res, next) {
      var dn = parseDN('ou=people, o=example');
      if (dn.parentOf(req.dn)) {
        ...
      } else {
        ...
      }
    });

## equals(dn)

Returns a boolean indicating whether `this` is equivalent to the passed in `dn`
argument. `dn` can be a string or a DN.

    server.add('o=example', function(req, res, next) {
      if (req.dn.equals('cn=foo, ou=people, o=example')) {
        ...
      } else {
        ...
      }
    });

## parent()

Returns a DN object that is the direct parent of `this`.  If there is no parent
this can return `null` (e.g. `parseDN('o=example').parent()` will return null).

## toString()

Returns the string representation of `this`.

    server.add('o=example', function(req, res, next) {
      console.log(req.dn.toString());
    });
