---
title: Client API | ldapjs
markdown2extras: wiki-tables
logo-color: green
logo-font-family: google:Aldrich, Verdana, sans-serif
header-font-family: google:Aldrich, Verdana, sans-serif
---

# ldapjs Client API

This document covers the ldapjs client API and assumes that you are familiar
with LDAP. If you're not, read the [guide](http://ldapjs.org/guide.html) first.

# Create a client

The code to create a new client looks like:

    var ldap = require('ldapjs');
    var client = ldap.createClient({
      url: 'ldap://127.0.0.1:1389'
    });

You can use `ldap://` or `ldaps://`; the latter would connect over SSL (note
that this will not use the LDAP TLS extended operation, but literally an SSL
connection to port 636, as in LDAP v2). The full set of options to create a
client is:

||url|| a valid LDAP url.||
||socketPath|| If you're running an LDAP server over a Unix Domain Socket, use this.||
||log4js|| You can optionally pass in a log4js instance the client will use to acquire a logger.  The client logs all messages at the `Trace` level.||
||timeout||How long the client should let operations live for before timing out. Default is Infinity.||
||connectTimeout||How long the client should wait before timing out on TCP connections. Default is up to the OS.||
||reconnect||Whether or not to automatically reconnect (and rebind) on socket errors. Takes amount of time in millliseconds. Default is 1000. 0/false will disable altogether.||

## Connection management

As LDAP is a stateful protocol (as opposed to HTTP), having connections torn
down from underneath you is difficult to deal with. As such, the ldapjs client
will automatically reconnect when the underlying socket has errors.  You can
disable this behavior by passing `reconnect=false` in the options at construct
time, or just setting the reconnect property to false at any time.

On reconnect, the client will additionally automatically rebind (assuming you
ever successfully called bind).  Only after the rebind succeeds will other
operations be allowed back through; in the meantime all callbacks will receive
a `DisconnectedError`. If you never called `bind`, the client will allow
operations when the socket is connected.

Also, note that the client will emit a `timeout` event if an operation
times out, and you'll be passed in the request object that was offending. You
probably don't _need_ to listen on it, as the client will also return an error
in the callback of that request.  However, it is useful if you want to have a
catch-all.  An event of `connectTimout` will be emitted when the client fails to
get a socket in time; there are no arguments.  Note that this event will be
emitted (potentially) in reconnect scenarios as well.

## Common patterns

The last two parameters in every API are `controls` and `callback`. `controls`
can be either a single instance of a `Control` or an array of `Control` objects.
You can, and probably will, omit this option.

Almost every operation has the callback form of `function(err, res)` where err
will be an instance of an `LDAPError` (you can use `instanceof` to switch).
You probably won't need to check the `res` parameter, but it's there if you do.

# bind
`bind(dn, password, controls,callback)`

Performs a bind operation against the LDAP server.

The bind API only allows LDAP 'simple' binds (equivalent to HTTP Basic
Authentication) for now. Note that all client APIs can optionally take an array
of `Control` objects. You probably don't need them though...

If you have more than 1 connection in the connection pool, you will be called
back after *all* of the connections are bound, not just the first one.

Example:

    client.bind('cn=root', 'secret', function(err) {
      assert.ifError(err);
    });

# add
`add(dn, entry, controls, callback)`

Performs an add operation against the LDAP server.

Allows you to add an entry (which is just a plain JS object), and as always,
controls are optional.

Example:

    var entry = {
      cn: 'foo',
      sn: 'bar',
      email: ['foo@bar.com', 'foo1@bar.com'],
      objectclass: 'fooPerson'
    };
    client.add('cn=foo, o=example', entry, function(err) {
      assert.ifError(err);
    });

# compare
`compare(dn, attribute, value, controls, callback)`

Performs an LDAP compare operation with the given attribute and value against
the entry referenced by dn.

Example:

    client.compare('cn=foo, o=example', 'sn', 'bar', function(err, matched) {
      assert.ifError(err);

      console.log('matched: ' + matched);
    });

# del
`del(dn, controls, callbak)`


Deletes an entry from the LDAP server.

Example:

    client.del('cn=foo, o=example', function(err) {
      assert.ifError(err);
    });

# exop
`exop(name, value, controls, callback)`

Performs an LDAP extended operation against an LDAP server. `name` is typically
going to be an OID (well, the RFC says it must be; however, ldapjs has no such
restriction).  `value` is completely arbitrary, and is whatever the exop says it
should be.

Example (performs an LDAP 'whois' extended op):

    client.exop('1.3.6.1.4.1.4203.1.11.3', function(err, value, res) {
      assert.ifError(err);

      console.log('whois: ' + value);
    });

# modify
`modify(name, changes, controls, callback)`

Performs an LDAP modify operation against the LDAP server.  This API requires
you to pass in a `Change` object, which is described below.  Note that you can
pass in a single `Change` or an array of `Change` objects.

Example:

    var change = new ldap.Change({
      operation: 'add',
      modification: {
        pets: ['cat', 'dog']
      }
    });

    client.modify('cn=foo, o=example', change, function(err) {
      assert.ifError(err);
    });

## Change

A `Change` object maps to the LDAP protocol of a modify change, and requires you
to set the `operation` and `modification`.  The `operation` is a string, and
must be one of:

||replace||Replaces the attribute referenced in `modification`.  If the modification has no values, it is equivalent to a delete.||
||add||Adds the attribute value(s) referenced in `modification`.  The attribute may or may not already exist.||
||delete||Deletes the attribute (and all values) referenced in `modification`.||

`modification` is just a plain old JS object with the values you want.

# modifyDN
`modifyDN(dn, newDN, controls, callback)`

Performs an LDAP modifyDN (rename) operation against an entry in the LDAP
server.  A couple points with this client API:

* There is no ability to set "keep old dn."  It's always going to flag the old
dn to be purged.
* The client code will automagically figure out if the request is a "new
superior" request ("new superior" means move to a different part of the tree,
as opposed to just renaming the leaf).

Example:

    client.modifyDN('cn=foo, o=example', 'cn=bar', function(err) {
      assert.ifError(err);
    });

# search
`search(base, options, controls, callback)`

Performs a search operation against the LDAP server.

The search operation is more complex than the other operations, so this one
takes an `options` object for all the parameters.  However, ldapjs makes some
defaults for you so that if you pass nothing in, it's pretty much equivalent
to an HTTP GET operation (i.e., base search against the DN, filter set to
always match).

Like every other operation, `base` is a DN string.  Options has the following
fields:

||scope||One of `base`, `one`, or `sub`. Defaults to `base`.||
||filter||A string version of an LDAP filter (see below), or a programatically constructed `Filter` object. Defaults to `(objectclass=*)`.||
||attributes||attributes to select and return (if these are set, the server will return *only* these attributes). Defaults to the empty set, which means all attributes.||
||attrsOnly||boolean on whether you want the server to only return the names of the attributes, and not their values.  Borderline useless.  Defaults to false.||
||sizeLimit||the maximum number of entries to return. Defaults to 0 (unlimited).||
||timeLimit||the maximum amount of time the server should take in responding, in seconds. Defaults to 10.  Lots of servers will ignore this.||

Responses from the `search` method are an `EventEmitter` where you will get a
notification for each `searchEntry` that comes back from the server.  You will
additionally be able to listen for a `searchReference`, `error` and `end` event.
Note that the `error` event will only be for client/TCP errors, not LDAP error
codes like the other APIs.  You'll want to check the LDAP status code
(likely for `0`) on the `end` event to assert success.  LDAP search results
can give you a lot of status codes, such as time or size exceeded, busy,
inappropriate matching, etc., which is why this method doesn't try to wrap up
the code matching.

Example:

    var opts = {
      filter: '(&(l=Seattle)(email=*@foo.com))',
      scope: 'sub'
    };

    client.search('o=example', opts, function(err, res) {
      assert.ifError(err);

      res.on('searchEntry', function(entry) {
        console.log('entry: ' + JSON.stringify(entry.object));
      });
      res.on('searchReference', function(referral) {
        console.log('referral: ' + referral.uris.join());
      });
      res.on('error', function(err) {
        console.error('error: ' + err.message);
      });
      res.on('end', function(result) {
        console.log('status: ' + result.status);
      });
    });

## Filter Strings

The easiest way to write search filters is to write them compliant with RFC2254,
which is "The string representation of LDAP search filters."  Note that
ldapjs doesn't support extensible matching, since it's one of those features
that almost nobody actually uses in practice.

Assuming you don't really want to read the RFC, search filters in LDAP are
basically are a "tree" of attribute/value assertions, with the tree specified
in prefix notation.  For example, let's start simple, and build up a complicated
filter.  The most basic filter is equality, so let's assume you want to search
for an attribute `email` with a value of `foo@bar.com`.  The syntax would be:

    (email=foo@bar.com)

ldapjs requires all filters to be surrounded by '()' blocks. Ok, that was easy.
Let's now assume you want to find all records where the email is actually just
anything in the "@bar.com" domain, and the location attribute is set to Seattle:

    (&(email=*@bar.com)(l=Seattle))

Now our filter is actually three LDAP filters.  We have an `and` filter,
an `equality` filter (the l=Seattle), and a `substring` filter.  Substrings are
wildcard filters.  Now, let's say we want to also set our filter to include a
specification that either the employeeType *not* be a manager or a secretary:

    (&(email=*@bar.com)(l=Seattle)(!(|(employeeType=manager)(employeeType=secretary))))

It gets a little bit complicated, but it's actually quite powerful, and lets you
find almost anything you're looking for.

# unbind
`unbind(callback)`

Performs an unbind operation against the LDAP server.

The unbind operation takes no parameters other than a callback, and will unbind
(and disconnect) *all* of the connections in the pool.

Example:

    client.unbind(function(err) {
      assert.ifError(err);
    });
