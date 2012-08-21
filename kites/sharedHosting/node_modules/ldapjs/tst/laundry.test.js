// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var test = require('tap').test;
var uuid = require('node-uuid');

var ldap = require('../lib/index');


///--- Globals

var SOCKET = '/tmp/.' + uuid();
var SUFFIX = 'dc=' + uuid();

var client;
var server;



///--- Helper

function search(t, options, callback) {
  client.search(SUFFIX, options, function(err, res) {
    t.ifError(err);
    t.ok(res);
    var found = false;
    res.on('searchEntry', function(entry) {
      t.ok(entry);
      found = true;
    });
    res.on('end', function() {
      t.ok(found);
      if (callback)
        return callback();

      t.end();
    });
  });
}



///--- Tests

test('setup', function(t) {
  server = ldap.createServer();
  t.ok(server);
  server.listen(SOCKET, function() {
    client = ldap.createClient({
      socketPath: SOCKET
    });
    t.ok(client);
    t.end();
  });

  server.bind('cn=root', function(req, res, next) {
    res.end();
    return next();
  });
  server.search(SUFFIX, function(req, res, next) {
    var entry = {
      dn: 'cn=foo, ' + SUFFIX,
      attributes: {
        objectclass: ['person', 'top'],
        cn: 'Pogo Stick',
        sn: 'Stick',
        givenname: 'ogo',
        mail: uuid() + '@pogostick.org'
      }
    };

    if (req.filter.matches(entry.attributes))
      res.send(entry);

    res.end();
  });
});


test('Evolution search filter (GH-3)', function(t) {
  // This is what Evolution sends, when searching for a contact 'ogo'. Wow.
  var filter =
    '(|(cn=ogo*)(givenname=ogo*)(sn=ogo*)(mail=ogo*)(member=ogo*)' +
    '(primaryphone=ogo*)(telephonenumber=ogo*)(homephone=ogo*)(mobile=ogo*)' +
    '(carphone=ogo*)(facsimiletelephonenumber=ogo*)' +
    '(homefacsimiletelephonenumber=ogo*)(otherphone=ogo*)' +
    '(otherfacsimiletelephonenumber=ogo*)(internationalisdnnumber=ogo*)' +
    '(pager=ogo*)(radio=ogo*)(telex=ogo*)(assistantphone=ogo*)' +
    '(companyphone=ogo*)(callbackphone=ogo*)(tty=ogo*)(o=ogo*)(ou=ogo*)' +
    '(roomnumber=ogo*)(title=ogo*)(businessrole=ogo*)(managername=ogo*)' +
    '(assistantname=ogo*)(postaladdress=ogo*)(l=ogo*)(st=ogo*)' +
    '(postofficebox=ogo*)(postalcode=ogo*)(c=ogo*)(homepostaladdress=ogo*)' +
    '(mozillahomelocalityname=ogo*)(mozillahomestate=ogo*)' +
    '(mozillahomepostalcode=ogo*)(mozillahomecountryname=ogo*)' +
    '(otherpostaladdress=ogo*)(jpegphoto=ogo*)(usercertificate=ogo*)' +
    '(labeleduri=ogo*)(displayname=ogo*)(spousename=ogo*)(note=ogo*)' +
    '(anniversary=ogo*)(birthdate=ogo*)(mailer=ogo*)(fileas=ogo*)' +
    '(category=ogo*)(calcaluri=ogo*)(calfburl=ogo*)(icscalendar=ogo*))';

  return search(t, filter);
});


test('GH-49 Client errors on bad attributes', function(t) {
  var searchOpts = {
    filter: 'cn=*ogo*',
    scope: 'one',
    attributes: 'dn'
  };
  return search(t, searchOpts);
});


test('GH-55 Client emits connect multiple times', function(t) {
  var c = ldap.createClient({
    socketPath: SOCKET
  });

  var count = 0;
  c.on('connect', function(socket) {
    t.ok(socket);
    count++;
  });
  c.bind('cn=root', 'secret', function(err, res) {
    t.ifError(err);
    c.unbind(function() {
      t.equal(count, 1);
      t.end();
    });
  });
});


test('shutdown', function(t) {
  client.unbind(function() {
    server.on('close', function() {
      t.end();
    });
    server.close();
  });
});
