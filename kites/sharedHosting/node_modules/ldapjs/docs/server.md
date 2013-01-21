---
title: Server API | ldapjs
markdown2extras: wiki-tables
logo-color: green
logo-font-family: google:Aldrich, Verdana, sans-serif
header-font-family: google:Aldrich, Verdana, sans-serif
---

# ldapjs Server API

This document covers the ldapjs server API and assumes that you are familiar
with LDAP. If you're not, read the [guide](http://ldapjs.org/guide.html) first.

# Create a server

The code to create a new server looks like:

    var server = ldap.createServer();

The full list of options is:

||log4js||You can optionally pass in a log4js instance the client will use to acquire a logger.  You'll need to set the level to `TRACE` to get any output from the client.||
||certificate||A PEM-encoded X.509 certificate; will cause this server to run in TLS mode.||
||key||A PEM-encoded private key that corresponds to _certificate_ for SSL.||

## Properties on the server object

### maxConnections

Set this property to reject connections when the server's connection count gets
high.

### connections (getter only)

The number of concurrent connections on the server.

### url

Returns the fully qualified URL this server is listening on. For example:
`ldaps://10.1.2.3:1636`.  If you haven't yet called `listen`, it will always
return `ldap://localhost:389`.

### Event: 'close'
`function() {}`

Emitted when the server closes.

## Listening for requests

The LDAP server API wraps up and mirrors the node
[listen](http://nodejs.org/docs/v0.4.11/api/net.html#server.listen) family of
APIs.

After calling `listen`, the property `url` on the server object itself will be
available.

Example:

     server.listen(389, '127.0.0.1', function() {
       console.log(LDAP server listening at: ' + server.url);
     });


### Port and Host
`listen(port, [host], [callback])`

Begin accepting connections on the specified port and host. If the host is
omitted, the server will accept connections directed to any IPv4 address
(INADDR_ANY).

This function is asynchronous. The last parameter callback will be called when
the server has been bound.

### Unix Domain Socket
`listen(path, [callback])`

Start a UNIX socket server listening for connections on the given path.

This function is asynchronous. The last parameter callback will be called when
the server has been bound.

### File descriptor
`listenFD(fd)`

Start a server listening for connections on the given file descriptor.

This file descriptor must have already had the `bind(2)` and `listen(2)` system
calls invoked on it. Additionally, it must be set non-blocking; try
`fcntl(fd, F_SETFL, O_NONBLOCK)`.

# Routes

The LDAP server API is meant to be the LDAP-equivalent of the express/sinatra
paradigm of programming.  Essentially every method is of the form
`OP(req, res, next)` where OP is one of bind, add, del, etc.  You can chain
handlers together by calling `next()` and ordering your functions in the
definition of the route.  For example:

    function authorize(req, res, next) {
      if (!req.connection.ldap.bindDN.equals('cn=root'))
        return next(new ldap.InsufficientAccessRightsError());

      return next();
    }

    server.search('o=example', authorize, function(req, res, next) { ... });

Note that ldapjs is also slightly different, since it's often going to be backed
to a DB-like entity, in that it also has an API where you can pass in a
'backend' object.  This is necessary if there are persistent connection pools,
caching, etc. that need to be placed in an object.

For example [ldapjs-riak](https://github.com/mcavage/node-ldapjs-riak) is a
complete implementation of the LDAP protocol over
[Riak](http://www.basho.com/products_riak_overview.php).  Getting an LDAP
server up with riak looks like:

    var ldap = require('ldapjs');
    var ldapRiak = require('ldapjs-riak');

    var server = ldap.createServer();
    var backend = ldapRiak.createBackend({
      "host": "localhost",
      "port": 8098,
      "bucket": "example",
      "indexes": ["l", "cn"],
      "uniqueIndexes": ["uid"],
      "numConnections": 5
    });

    server.add("o=example",
               backend,
               backend.add());
    ...

The first parameter to an ldapjs route is always the point in the
tree to mount the handler chain at.  The second argument is _optionally_ a
backend object.  After that you can pass in an arbitrary combination of
functions in the form `f(req, res, next)` or arrays of functions of the same
signature (ldapjs will unroll them).

Unlike HTTP, LDAP operations do not have a heterogeneous wire format, so each
operation requires specific methods/fields on the request/response
objects.  However, there is a `.use()` method availabe, similar to
that on express/connect, allowing you to chain up "middleware":

    server.use(function(req, res, next) {
      console.log('hello world');
      return next();
    });

## Common Request Elements

All request objects have the `dn` getter on it, which is "context-sensitive"
and returns the point in the tree that the operation wants to operate on.  The
LDAP protocol itself sadly doesn't define operations this way, and has a unique
name for just about every op.  So, ldapjs calls it `dn`.  The DN object itself
is documented at [DN](/dn.html).

All requests have an optional array of `Control` objects.  `Control` will have
the properties `type` (string), `criticality` (boolean), and optionally, a
string `value`.

All request objects will have a `connection` object, which is the `net.Socket`
associated to this request.  Off the `connection` object is an `ldap` object.
The most important property to pay attention to is the `bindDN` property
which will be an instance of an `ldap.DN` object.  This is what the client
authenticated as on this connection. If the client didn't bind, then a DN object
will be there defaulted to `cn=anonymous`.

Additionally, request will have a `logId` parameter you can use to uniquely
identify the request/connection pair in logs (includes the LDAP messageID).

## Common Response Elements

All response objects will have an `end` method on them.  By default, calling
`res.end()` with no arguments will return SUCCESS (0x00) to the client
(with the exception of `compare` which will return COMPARE_TRUE (0x06)).  You
can pass in a status code to the `end()` method to return an alternate status
code.

However, it's more common/easier to use the `return next(new LDAPError())`
pattern, since ldapjs will fill in the extra LDAPResult fields like matchedDN
and error message for you.

## Errors

ldapjs includes an exception hierarchy that directly corresponds to the RFC list
of error codes.  The complete list is documented in [errors](/errors.html). But
the paradigm is something defined like CONSTRAINT_VIOLATION in the RFC would be
`ConstraintViolationError` in ldapjs.  Upon calling `next(new LDAPError())`,
ldapjs will _stop_ calling your handler chain.  For example:

    server.search('o=example',
      function(req, res, next) { return next(); },
      function(req, res, next) { return next(new ldap.OperationsError()); },
      function(req, res, next) { res.end(); }
    );

In the code snipped above, the third handler would never get invoked.

# Bind

Adds a mount in the tree to perform LDAP binds with. Example:

    server.bind('ou=people, o=example', function(req, res, next) {
      console.log('bind DN: ' + req.dn.toString());
      console.log('bind PW: ' + req.credentials);
      res.end();
    });

## BindRequest

BindRequest objects have the following properties:

### version

The LDAP protocol version the client is requesting to run this connection on.
Note that ldapjs only supports LDAP version 3.

### name

The DN the client is attempting to bind as (note this is the same as the `dn`
property).

### authentication

The method of authentication.  Right now only `simple` is supported.

### credentials

The credentials to go with the `name/authentication` pair.  For `simple`, this
will be the plain-text password.

## BindResponse

No extra methods above an `LDAPResult` API call.

# Add

Adds a mount in the tree to perform LDAP adds with.

    server.add('ou=people, o=example', function(req, res, next) {
      console.log('DN: ' + req.dn.toString());
      console.log('Entry attributes: ' + req.toObject().attributes);
      res.end();
    });

## AddRequest

AddRequest objects have the following properties:

### entry

The DN the client is attempting to add (this is the same as the `dn`
property).

### attributes

The set of attributes in this entry.  This will be an array of
`Attribute` objects (which have a type and an array of values).  This directly
maps to how the request came in off the wire.  It's likely you'll want to use
`toObject()` and iterate that way, since that will transform an AddRequest into
a standard JavaScript object.

### toObject()

This operation will return a plain JavaScript object from the request that looks
like:

    {
      dn: 'cn=foo, o=example',  // string, not DN object
      attributes: {
        cn: ['foo'],
        sn: ['bar'],
        objectclass: ['person', 'top']
      }
    }

## AddResponse

No extra methods above an `LDAPResult` API call.

# Search

Adds a handler for the LDAP search operation.

    server.search('o=example', function(req, res, next) {
      console.log('base object: ' + req.dn.toString());
      console.log('scope: ' + req.scope);
      console.log('filter: ' + req.filter.toString());
      res.end();
    });

## SearchRequest

SearchRequest objects have the following properties:

### baseObject

The DN the client is attempting to start the search at (equivalent to `dn`).

### scope

(string) one of:

* base
* one
* sub

### derefAliases

An integer (defined in the LDAP protocol). Defaults to '0' (meaning
never deref).

### sizeLimit

The number of entries to return. Defaults to '0' (unlimited). ldapjs doesn't
currently automatically enforce this, but probably will at some point.

### timeLimit

Maximum amount of time the server should take in sending search entries.
Defaults to '0' (unlimited).

### typesOnly

Whether to return only the names of attributes, and not the values.  Defaults to
'false'.  ldapjs will take care of this for you.

### filter

The [filter](/filters.html) object that the client requested.  Notably this has
a `matches()` method on it that you can leverage.  For an example of
introspecting a filter, take a look at the ldapjs-riak source.

### attributes

An optional list of attributes to restrict the returned result sets to. ldapjs
will automatically handle this for you.

## SearchResponse

### send(entry)

Allows you to send a `SearchEntry` object.  You do not need to
explicitly pass in a `SearchEntry` object, and can instead just send a plain
JavaScript object that matches the format used from `AddRequest.toObject()`.


    server.search('o=example', function(req, res, next) {
      var obj = {
        dn: 'o=example',
        attributes: {
          objectclass: ['top', 'organization'],
          o: ['example']
        }
      };

      if (req.filter.matches(obj))
        res.send(obj)

      res.end();
    });

# modify

Allows you to handle an LDAP modify operation.

    server.modify('o=example', function(req, res, next) {
      console.log('DN: ' + req.dn.toString());
      console.log('changes:');
      req.changes.forEach(function(c) {
        console.log('  operation: ' + c.operation);
        console.log('  modification: ' + c.modification.toString());
      });
      res.end();
    });

## ModifyRequest

ModifyRequest objects have the following properties:

### object

The DN the client is attempting to update (this is the same as the `dn`
property).

### changes

An array of `Change` objects the client is attempting to perform. See below for
details on the `Change` object.

## Change

The `Change` object will have the following properties:

### operation

A string, and will be one of: 'add', 'delete', or 'replace'.

### modification

Will be an `Attribute` object, which will have a 'type' (string) field, and
'vals', which will be an array of string values.

## ModifyResponse

No extra methods above an `LDAPResult` API call.

# del

Allows you to handle an LDAP delete operation.

    server.del('o=example', function(req, res, next) {
      console.log('DN: ' + req.dn.toString());
      res.end();
    });

## DeleteRequest

### entry

The DN the client is attempting to delete (this is the same as the `dn`
property).

## DeleteResponse

No extra methods above an `LDAPResult` API call.

# compare

Allows you to handle an LDAP compare operation.

    server.compare('o=example', function(req, res, next) {
      console.log('DN: ' + req.dn.toString());
      console.log('attribute name: ' + req.attribute);
      console.log('attribute value: ' + req.value);
      res.end(req.value === 'foo');
    });

## CompareRequest

### entry

The DN the client is attempting to compare (this is the same as the `dn`
property).

### attribute

The string name of the attribute to compare values of.

### value

The string value of the attribute to compare.

## CompareResponse

The `end()` method for compare takes a boolean, as opposed to a numeric code
(you can still pass in a numeric LDAP status code if you want). Beyond
that, there are no extra methods above an `LDAPResult` API call.

# modifyDN

Allows you to handle an LDAP modifyDN operation.

    server.modifyDN('o=example', function(req, res, next) {
      console.log('DN: ' + req.dn.toString());
      console.log('new RDN: ' + req.newRdn.toString());
      console.log('deleteOldRDN: ' + req.deleteOldRdn);
      console.log('new superior: ' +
        (req.newSuperior ? req.newSuperior.toString() : ''));

      res.end();
    });

## ModifyDNRequest

### entry

The DN the client is attempting to rename (this is the same as the `dn`
property).

### newRdn

The leaf RDN the client wants to rename this entry to. This will be a DN object.

### deleteOldRdn

Whether or not to delete the old RDN (i.e., rename vs copy). Defaults to 'true'.

### newSuperior

Optional (DN).  If the modifyDN operation wishes to relocate the entry in the
tree, the `newSuperior` field will contain the new parent.

## ModifyDNResponse

No extra methods above an `LDAPResult` API call.

# exop

Allows you to handle an LDAP extended operation. Extended operations are pretty
much arbitrary extensions, by definition.  Typically the extended 'name' is an
OID, but ldapjs makes no such restrictions; it just needs to be a string.
Unlike the other operations, extended operations don't map to any location in
the tree, so routing here will be exact match, as opposed to subtree.

    // LDAP whoami
    server.exop('1.3.6.1.4.1.4203.1.11.3', function(req, res, next) {
      console.log('name: ' + req.name);
      console.log('value: ' + req.value);
      res.value = 'u:xxyyz@EXAMPLE.NET';
      res.end();
      return next();
    });

## ExtendedRequest

### name

Will always be a match to the route-defined name.  Clients must include this
in their requests.

### value

Optional string. The arbitrary blob the client sends for this extended
operation.

## ExtendedResponse

### name

The name of the extended operation. ldapjs will automatically set this.

### value

The arbitrary (string) value to send back as part of the response.

# unbind

ldapjs by default provides an unbind handler that just disconnects the client
and cleans up any internals (in ldapjs core).  You can override this handler
if you need to clean up any items in your backend, or perform any other cleanup
tasks you need to.

    server.unbind(function(req, res, next) {
      res.end();
    });

Note that the LDAP unbind operation actually doesn't send any response (by
definition in the RFC), so the UnbindResponse is really just a stub that
ultimately calls `net.Socket.end()` for you. There are no properties available
on either the request or response objects, except, of course, for `end()` on the
response.
