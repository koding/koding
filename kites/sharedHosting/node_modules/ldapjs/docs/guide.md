---
title: LDAP Guide | ldapjs
markdown2extras: wiki-tables
logo-color: green
logo-font-family: google:Aldrich, Verdana, sans-serif
header-font-family: google:Aldrich, Verdana, sans-serif
---

# LDAP Guide

This guide was written assuming that you (1) don't know anything about ldapjs,
and perhaps more importantly (2) know little, if anything about LDAP.  If you're
already an LDAP whiz, please don't read this and feel it's condescending.  Most
people don't know how LDAP works, other than that "it's that thing that has my
password."

By the end of this guide, we'll have a simple LDAP server that accomplishes a
"real" task.

# What exactly is LDAP?

If you haven't already read the
[wikipedia](http://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol)
entry (which you should go do right now), LDAP is the "Lightweight Directory
Access Protocol".  A directory service basically breaks down as follows:

* A directory is a tree of entries (similar to but different than an FS).
* Every entry has a unique name in the tree.
* An entry is a set of attributes.
* An attribute is a key/value(s) pairing (multivalue is natural).

It might be helpful to visualize:

                  o=example
                  /       \
             ou=users     ou=groups
            /      |         |     \
        cn=john  cn=jane    cn=dudes  cn=dudettes
        /
    keyid=foo


Let's say we wanted to look at the record cn=john:

    dn: cn=john, ou=users, o=example
    cn: john
    sn: smith
    email: john@example.com
    email: john.smith@example.com
    objectClass: person

A few things to note:

* All names in a directory tree are actually referred to as a _distinguished
name_, or _dn_ for short.  A dn is comprised of attributes that lead to that
node in the tree, as shown above (the syntax is foo=bar, ...).
* The root of the tree is at the right of the _dn_, which is inverted from a
filesystem hierarchy.
* Every entry in the tree is an _instance of_ an _objectclass_.
* An _objectclass_ is a schema concept; think of it like a table in a
traditional ORM.
* An _objectclass_ defines what _attributes_ an entry can have (on the ORM
analogy, an _attribute_ would be like a column).

That's it. LDAP, then, is the protocol for interacting with the directory tree,
and it's comprehensively specified for common operations, like
add/update/delete and importantly, search.  Really, the power of LDAP comes
through the search operations defined in the protocol, which are richer
than HTTP query string filtering, but less powerful than full SQL.  You can
think of LDAP as a NoSQL/document store with a well-defined query syntax.

So, why isn't LDAP more popular for a lot of applications? Like anything else
that has "simple" or "lightweight" in the name, it's not really that
lightweight. In particular, almost all of the implementations of LDAP stem
from the original University of Michigan codebase written in 1996. At that
time, the original intention of LDAP was to be an IP-accessible gateway to the
much more complex X.500 directories,  which means that a lot of that
baggage has carried through to today.  That makes for a high barrier to entry,
when most applications just don't need most of those features.

## How is ldapjs any different?

Well, on the one hand, since ldapjs has to be 100% wire compatible with LDAP to
be useful, it's not. On the other hand, there are no forced assumptions about
what you need and don't need for your use of a directory system.  For example,
want to run with no-schema in OpenLDAP/389DS/et al? Good luck.  Most of the
server implementations support arbitrary "backends" for persistence, but really
you'll be using [BDB](http://www.oracle.com/technetwork/database/berkeleydb/overview/index.html).

Want to run schema-less in ldapjs, or wire it up with some mongoose models? No
problem.  Want to back it to redis? Should be able to get some basics up in a
day or two.

Basically, the ldapjs philospohy is to deal with the "muck" of LDAP, and then
get out of the way so you can just use the "good parts."

# Ok, cool. Learn me some LDAP!

With the initial fluff out of the way, let's do something crazy to teach
you some LDAP.  Let's put an LDAP server up over the top of your (Linux) host's
/etc/passwd and /etc/group files. Usually sysadmins "go the other way," and
replace /etc/passwd with a
[PAM](http://en.wikipedia.org/wiki/Pluggable_authentication_module "Pluggable
authentication module") module to LDAP. While this is probably not a super
useful real-world use case, it will teach you some of the basics. If it is
useful to you, then that's gravy.

## Install

If you don't already have node.js and npm, clearly you need those, so follow
the steps at [nodejs.org](http://nodejs.org) and [npmjs.org](http://npmjs.org),
respectively.  After that, run:

    $ npm install ldapjs

Rather than overload you with client-side programming for now, we'll use
the OpenLDAP CLI to interact with our server.  It's almost certainly already
installed on your system, but if not, you can get it from brew/apt/yum/your
package manager here.

To get started, open some file, and let's get the library loaded and a server
created:

    var ldap = require('ldapjs');

    var server = ldap.createServer();

    server.listen(1389, function() {
      console.log('/etc/passwd LDAP server up at: %s', server.url);
    });

And run that.  Doing anything will give you errors (LDAP "No Such Object")
since we haven't added any support in yet, but go ahead and try it anyway:

    $ ldapsearch -H ldap://localhost:1389 -x -b "o=myhost" objectclass=*

Before we go any further, note that the complete code for the server we are
about to build up is on the [examples](http://ldapjs.org/examples.html) page.

## Bind

So, lesson #1 about LDAP: unlike HTTP, it's connection-oriented; that means that
you authenticate (in LDAP nomenclature this is called a _bind_), and all
subsequent operations operate at the level of priviledge you established during
a bind.  You can bind any number of times on a single connection and change that
identity.  Technically, it's optional, and you can support _anonymous_
operations from clients, but (1) you probably don't want that, and (2) most
LDAP clients will initiate a bind anyway (OpenLDAP will), so let's add it in
and get it out of our way.

What we're going to do is add a "root" user to our LDAP server.  This root user
has no correspondence to our Unix root user, it's just something we're making up
and going to use for allowing an (LDAP) admin to do anything.  To do so, add
this code into your file:

    server.bind('cn=root', function(req, res, next) {
      if (req.dn.toString() !== 'cn=root' || req.credentials !== 'secret')
        return next(new ldap.InvalidCredentialsError());

      res.end();
      return next();
    });

Not very secure, but this is a demo.  What we did there was "mount" a tree in
the ldapjs server, and add a handler for the _bind_ method.  If you've ever used
express, this pattern should be really familiar; you can add any number of
handlers in, as we'll see later.

On to the meat of the method.  What's up with this?

    if (req.dn.toString() !== 'cn=root' || req.credentials !== 'secret')

The first part `req.dn.toString() !== 'cn=root'`:  you're probably thinking
"WTF?!? Does ldapjs allow something other than cn=root into this handler?" Sort
of.  It allows cn=root *and any children* into that handler.  So the entries
`cn=root` and `cn=evil, cn=root` would both match and flow into this handler.
Hence that check.  The second check `req.credentials` is probably obvious, but
it brings up an important point, and that is the `req`, `res` objects in ldapjs
are not homogenous across server operation types.  Unlike HTTP, there's not a
single message format, so each of the operations has fields and functions
appropriate to that type.  The LDAP bind operation has `credentials`, which are
a string representation of the client's password.  This is logically the same as
HTTP Basic Authentication (there are other mechanisms, but that's out of scope
for a getting started guide).  Ok, if either of those checks failed, we pass a
new ldapjs `Error` back into the server, and it will (1) halt the chain, and (2)
send the proper error code back to the client.

Lastly, assuming that this request was ok, we just end the operation with
`res.end()`.  The `return next()` isn't strictly necessary, since here we only
have one handler in the chain, but it's good habit to always do that, so if you
add another handler in later you won't get bit by it not being invoked.

Blah blah, let's try running the ldap client again, first with a bad password:

    $ ldapsearch -H ldap://localhost:1389 -x -D cn=root -w foo -b "o=myhost" objectclass=*

    ldap_bind: Invalid credentials (49)
        matched DN: cn=root
        additional info: Invalid Credentials

And again with the correct one:

    $ ldapsearch -H ldap://localhost:1389 -x -D cn=root -w secret -LLL -b "o=myhost" objectclass=*

    No such object (32)
    Additional information: No tree found for: o=myhost

Don't worry about all the flags we're passing into OpenLDAP, that's just to make
their CLI less annonyingly noisy.  This time, we got another `No such object`
error, but it's for the tree `o=myhost`. That means our bind went through, and
our search failed, since we haven't yet added a search handler. Just one more
small thing to do first.

Remember earlier I said there were no authorization rules baked into LDAP? Well,
we added a bind route, so the only user that can authenticate is `cn=root`, but
what if the remote end doesn't authenticate at all? Right, nothing says they
*have to* bind, that's just what the common clients do.  Let's add a quick
authorization handler that we'll use in all our subsequent routes:

    function authorize(req, res, next) {
      if (!req.connection.ldap.bindDN.equals('cn=root'))
        return next(new ldap.InsufficientAccessRightsError());

      return next();
    }

Should be pretty self-explanatory, but as a reminder, LDAP is connection
oriented, so we check that the connection remote user was indeed our `cn=root`
(by default ldapjs will have a DN of `cn=anonymous` if the client didn't bind).

## Search

We said we wanted to allow LDAP operations over /etc/passwd, so let's detour
for a moment to explain an /etc/passwd record.

    jsmith:x:1001:1000:Joe Smith,Room 1007,(234)555-8910,(234)555-0044,email:/home/jsmith:/bin/sh

The sample record above maps to:

||jsmith||user name.||
||x||historically this contained the password hash, but that's usually in /etc/shadow now, so you get an 'x'.||
||1001||the unix numeric user id.||
||1000||the unix numeric group id. (primary).||
||'Joe Smith,...'||the "gecos," which is a description, and is usually a comma separated list of contact details.||
||/home/jsmith||the user's home directory.||
||/bin/sh||the user's shell.||

Let's write some handlers to parse that and transform it into an LDAP search
record (note, you'll need to add `var fs = require('fs');` at the top of the
source file).

First, make a handler that just loads the "user database" in a "pre" handler:

    function loadPasswdFile(req, res, next) {
      fs.readFile('/etc/passwd', 'utf8', function(err, data) {
        if (err)
          return next(new ldap.OperationsError(err.message));

        req.users = {};

        var lines = data.split('\n');
        for (var i = 0; i < lines.length; i++) {
          if (!lines[i] || /^#/.test(lines[i]))
            continue;

          var record = lines[i].split(':');
          if (!record || !record.length)
            continue;

          req.users[record[0]] = {
            dn: 'cn=' + record[0] + ', ou=users, o=myhost',
            attributes: {
              cn: record[0],
              uid: record[2],
              gid: record[3],
              description: record[4],
              homedirectory: record[5],
              shell: record[6] || '',
              objectclass: 'unixUser'
            }
          };
        }

        return next();
      });
    }

Ok, all that did is tack the /etc/passwd records onto req.users so that any
subsequent handler doesn't have to reload the file.  Next, let's write a search
handler to process that:

    var pre = [authorize, loadPasswdFile];

    server.search('o=myhost', pre, function(req, res, next) {
      Object.keys(req.users).forEach(function(k) {
        if (req.filter.matches(req.users[k].attributes))
          res.send(req.users[k]);
      });

      res.end();
      return next();
    });

And try running:

    $ ldapsearch -H ldap://localhost:1389 -x -D cn=root -w secret -LLL -b "o=myhost" cn=root
    dn: cn=root, ou=users, o=myhost
    cn: root
    uid: 0
    gid: 0
    description: System Administrator
    homedirectory: /var/root
    shell: /bin/sh
    objectclass: unixUser

Sweet! Try this out too:

    $ ldapsearch -H ldap://localhost:1389 -x -D cn=root -w secret -LLL -b "o=myhost" objectclass=*
    ...

You should have seen an entry for every record in /etc/passwd with the second.
What all did we do here?  A lot.  Let's break this down...

### What did I just do on the command line?

Let's start with looking at what you even asked for:

    $ ldapsearch -H ldap://localhost:1389 -x -D cn=root -w secret -LLL -b "o=myhost" cn=root

We can throw away `ldapsearch -H -x -D -w -LLL`, as those just specify the URL
to connect to, the bind credentials and the `-LLL` just quiets down OpenLDAP.
That leaves us with: `-b "o=myhost" cn=root`.

The `-b o=myhost` tells our LDAP server where to _start_ looking in
the tree for entries that might match the search filter, which above is
`cn=root`.

In this little LDAP example, we're mostly throwing out any qualification of the
"tree," since there's not actually a tree in /etc/passwd (we will extend later
with /etc/group).  Remember how I said ldapjs gets out of the way and doesn't
force anything on you?  Here's an example.  If we wanted an LDAP server to run
over the filesystem, we actually would use this, but here, meh.

Next, `cn=root` is the search "filter".  LDAP has a rich specification of
filters, where you can specify `and`, `or`, `not`, `>=`, `<=`, `equal`,
`wildcard`, `present` and a few other esoteric things.  Really, `equal`,
`wildcard`, `present` and the boolean operators are all you'll likely ever need.
So, the filter `cn=root` is an "equality" filter, and says to only return
entries that have attributes that match that.  In the second invocation, we used
a 'presence' filter, to say 'return any entries that have an objectclass'
attribute, which in LDAP parlance is saying "give me everything."

### The code

In the code above, let's ignore the fs and split stuff, since really all we
did was read in /etc/passwd line by line.  After that, we looked at each record
and made the cheesiest transform ever, which is making up a "search entry." A
search entry _must_ have a DN so the client knows what record it is, and a set
of attributes.  So that's why we did this:

    var entry = {
      dn: 'cn=' + record[0] + ', ou=users, o=myhost',
      attributes: {
        cn: record[0],
        uid: record[2],
        gid: record[3],
        description: record[4],
        homedirectory: record[5],
        shell: record[6] || '',
        objectclass: 'unixUser'
      }
    };

Next, we let ldapjs do all the hard work of figuring out LDAP search filters
for us by calling `req.filter.matches`.  If it matched, we return the whole
record with `res.send`.  In this little example we're running O(n), so for
something big and/or slow, you'd have to do some work to effectively write a
query planner (or just not support it...). For some reference code, check out
`node-ldapjs-riak`, which takes on the fairly difficult task of writing a 'full'
LDAP server over riak.

To demonstrate what ldapjs is doing for you, let's find all users who have a
shell set to `/bin/false` and whose name starts with `p` (I'm doing this
on Ubuntu).  Then, let's say we only care about their login name and primary
group id.  We'd do this:

    $ ldapsearch -H ldap://localhost:1389 -x -D cn=root -w secret -LLL -b "o=myhost" "(&(shell=/bin/false)(cn=p*))" cn gid
    dn: cn=proxy, ou=users, o=myhost
    cn: proxy
    gid: 13

    dn: cn=pulse, ou=users, o=myhost
    cn: pulse
    gid: 114

## Add

This is going to be a little bit ghetto, since what we're going to do is just
use node's child process module to spawn calls to `adduser`.  Go ahead and add
the following code in as another handler (you'll need a
`var spawn = require('child_process').spawn;` at the top of your file):

    server.add('ou=users, o=myhost', pre, function(req, res, next) {
      if (!req.dn.rdns[0].cn)
        return next(new ldap.ConstraintViolationError('cn required'));

      if (req.users[req.dn.rdns[0].cn])
        return next(new ldap.EntryAlreadyExistsError(req.dn.toString()));

      var entry = req.toObject().attributes;

      if (entry.objectclass.indexOf('unixUser') === -1)
        return next(new ldap.ConstraintViolation('entry must be a unixUser'));

      var opts = ['-m'];
      if (entry.description) {
        opts.push('-c');
        opts.push(entry.description[0]);
      }
      if (entry.homedirectory) {
        opts.push('-d');
        opts.push(entry.homedirectory[0]);
      }
      if (entry.gid) {
        opts.push('-g');
        opts.push(entry.gid[0]);
      }
      if (entry.shell) {
        opts.push('-s');
        opts.push(entry.shell[0]);
      }
      if (entry.uid) {
        opts.push('-u');
        opts.push(entry.uid[0]);
      }
      opts.push(entry.cn[0]);
      var useradd = spawn('useradd', opts);

      var messages = [];

      useradd.stdout.on('data', function(data) {
        messages.push(data.toString());
      });
      useradd.stderr.on('data', function(data) {
        messages.push(data.toString());
      });

      useradd.on('exit', function(code) {
        if (code !== 0) {
          var msg = '' + code;
          if (messages.length)
            msg += ': ' + messages.join();
          return next(new ldap.OperationsError(msg));
        }

        res.end();
        return next();
      });
    });

Then, you'll need to be root to have this running, so start your server with
`sudo` (or be root, whatever).  Now, go ahead and create a file called
`user.ldif` with the following contents:

    dn: cn=ldapjs, ou=users, o=myhost
    objectClass: unixUser
    cn: ldapjs
    shell: /bin/bash
    description: Created via ldapadd

Now go ahead and invoke with:

    $ ldapadd -H ldap://localhost:1389 -x -D cn=root -w secret -f ./user.ldif
    adding new entry "cn=ldapjs, ou=users, o=myhost"

Let's confirm he got added with an ldapsearch:

    $ ldapsearch -H ldap://localhost:1389 -LLL -x -D cn=root -w secret -b "ou=users, o=myhost" cn=ldapjs
    dn: cn=ldapjs, ou=users, o=myhost
    cn: ldapjs
    uid: 1001
    gid: 1001
    description: Created via ldapadd
    homedirectory: /home/ldapjs
    shell: /bin/bash
    objectclass: unixUser

As before, here's a breakdown of the code:

    server.add('ou=users, o=myhost', pre, function(req, res, next) {
      if (!req.dn.rdns[0].cn)
        return next(new ldap.ConstraintViolationError('cn required'));

      if (req.users[req.dn.rdns[0].cn])
        return next(new ldap.EntryAlreadyExistsError(req.dn.toString()));

      var entry = req.toObject().attributes;

      if (entry.objectclass.indexOf('unixUser') === -1)
        return next(new ldap.ConstraintViolation('entry must be a unixUser'));

A few new things:

* We mounted this handler at `ou=users, o=myhost`. Why? What if we want to
extend this little project with groups?  We probably want those under a
different part of the tree.
* We did some really minimal schema enforcement by:
    + Checking that the leaf RDN (relative distinguished name) was a _cn_
attribute.
    + We then did `req.toObject()`. As mentioned before, each of the req/res
objects have special APIs that make sense for that operation.  Without getting
into the details, the LDAP add operation on the wire doesn't look like a JS
object, and we want to support both the LDAP nerd that wants to see what
got sent, and the "easy" case.  So use `.toObject()`.  Note we also filtered
out to the `attributes` portion of the object since that's all we're really
looking at.
    + Lastly, we did a super minimal check to see if the entry was of type
`unixUser`. Frankly for this case, it's kind of useless, but it does illustrate
one point: attribute names are case-insensitive, so ldapjs converts them all to
lower case (note the client sent _objectClass_ over the wire).

After that, we really just delegated off to the _useradd_ command.  As far as I
know, there is not a node.js module that wraps up `getpwent` and friends,
otherwise we'd use that.

Now, what's missing?  Oh, right, we need to let you set a password.  Well, let's
support that via the _modify_ command.

## Modify

Unlike HTTP, "partial" document updates are fully specified as part of the
RFC, so appending, removing, or replacing a single attribute is pretty natural.
Go ahead and add the following code into your source file:

    server.modify('ou=users, o=myhost', pre, function(req, res, next) {
      if (!req.dn.rdns[0].cn || !req.users[req.dn.rdns[0].cn])
        return next(new ldap.NoSuchObjectError(req.dn.toString()));

      if (!req.changes.length)
        return next(new ldap.ProtocolError('changes required'));

      var user = req.users[req.dn.rdns[0].cn].attributes;
      var mod;

      for (var i = 0; i < req.changes.length; i++) {
        mod = req.changes[i].modification;
        switch (req.changes[i].operation) {
        case 'replace':
          if (mod.type !== 'userpassword' || !mod.vals || !mod.vals.length)
            return next(new ldap.UnwillingToPerformError('only password updates ' +
                                                         'allowed'));
          break;
        case 'add':
        case 'delete':
          return next(new ldap.UnwillingToPerformError('only replace allowed'));
        }
      }

      var passwd = spawn('chpasswd', ['-c', 'MD5']);
      passwd.stdin.end(user.cn + ':' + mod.vals[0], 'utf8');

      passwd.on('exit', function(code) {
        if (code !== 0)
          return next(new ldap.OperationsError(code));

        res.end();
        return next();
      });
    });


Basically, we made sure the remote client was targeting an entry that exists,
ensuring that they were asking to "replace" the `userPassword` attribute (which
is the 'standard' LDAP attribute for passwords; if you think it's easier to use
'password', knock yourself out), and then just delegating to the `chpasswd`
command (which lets you change a user's password over stdin).  Next, go ahead
and create a `passwd.ldif` file:

    dn: cn=ldapjs, ou=users, o=myhost
    changetype: modify
    replace: userPassword
    userPassword: secret
    -

And then run the OpenLDAP CLI:

    $ ldapmodify -H ldap://localhost:1389 -x -D cn=root -w secret -f ./passwd.ldif

You should now be able to login to your box as the ldapjs user. Let's get
the last "mainline" piece of work out of the way, and delete the user.

## Delete

Delete is pretty straightforward. The client gives you a dn to delete, and you
delete it :).  Add the following code into your server:

    server.del('ou=users, o=myhost', pre, function(req, res, next) {
      if (!req.dn.rdns[0].cn || !req.users[req.dn.rdns[0].cn])
        return next(new ldap.NoSuchObjectError(req.dn.toString()));

      var userdel = spawn('userdel', ['-f', req.dn.rdns[0].cn]);

      var messages = [];
      userdel.stdout.on('data', function(data) {
        messages.push(data.toString());
      });
      userdel.stderr.on('data', function(data) {
        messages.push(data.toString());
      });

      userdel.on('exit', function(code) {
        if (code !== 0) {
          var msg = '' + code;
          if (messages.length)
            msg += ': ' + messages.join();
          return next(new ldap.OperationsError(msg));
        }

        res.end();
        return next();
      });
    });

And then run the following command:

    $ ldapdelete -H ldap://localhost:1389 -x -D cn=root -w secret "cn=ldapjs, ou=users, o=myhost"


# Where to go from here

The complete source code for this example server is available in
[examples](/examples.html).  Make sure to read up on the [server](/server.html)
and [client](/client.html) APIs.  If you're looking for a "drop in" solution,
take a look at [ldapjs-riak](https://github.com/mcavage/node-ldapjs-riak).

[Mozilla](https://wiki.mozilla.org/Mozilla_LDAP_SDK_Programmer%27s_Guide/Understanding_LDAP)
still maintains some web pages with LDAP overviews if you look around, if you're
looking for more tutorials.  After that, you'll need to work your way through
the [RFCs](http://tools.ietf.org/html/rfc4510) as you work through the APIs in
ldapjs.
