---
title: Examples | ldapjs
markdown2extras: wiki-tables
logo-color: green
logo-font-family: google:Aldrich, Verdana, sans-serif
header-font-family: google:Aldrich, Verdana, sans-serif
---

# ldapjs Examples

This page contains a (hopefully) growing list of sample code to get you started
with ldapjs.

# In-memory server

    var ldap = require('ldapjs');


    ///--- Shared handlers

    function authorize(req, res, next) {
      if (!req.connection.ldap.bindDN.equals('cn=root'))
        return next(new ldap.InsufficientAccessRightsError());

      return next();
    }


    ///--- Globals

    var SUFFIX = 'o=joyent';
    var db = {};
    var server = ldap.createServer();



    server.bind('cn=root', function(req, res, next) {
      if (req.dn.toString() !== 'cn=root' || req.credentials !== 'secret')
        return next(new ldap.InvalidCredentialsError());

      res.end();
      return next();
    });

    server.add(SUFFIX, authorize, function(req, res, next) {
      var dn = req.dn.toString();

      if (db[dn])
        return next(new ldap.EntryAlreadyExistsError(dn));

      db[dn] = req.toObject().attributes;
      res.end();
      return next();
    });

    server.bind(SUFFIX, function(req, res, next) {
      var dn = req.dn.toString();
      if (!db[dn])
        return next(new ldap.NoSuchObjectError(dn));

      if (!dn[dn].userpassword)
        return next(new ldap.NoSuchAttributeError('userPassword'));

      if (db[dn].userpassword !== req.credentials)
        return next(new ldap.InvalidCredentialsError());

      res.end();
      return next();
    });

    server.compare(SUFFIX, authorize, function(req, res, next) {
      var dn = req.dn.toString();
      if (!db[dn])
        return next(new ldap.NoSuchObjectError(dn));

      if (!db[dn][req.attribute])
        return next(new ldap.NoSuchAttributeError(req.attribute));

      var matches = false;
      var vals = db[dn][req.attribute];
      for (var i = 0; i < vals.length; i++) {
        if (vals[i] === req.value) {
          matches = true;
          break;
        }
      }

      res.end(matches);
      return next();
    });

    server.del(SUFFIX, authorize, function(req, res, next) {
      var dn = req.dn.toString();
      if (!db[dn])
        return next(new ldap.NoSuchObjectError(dn));

      delete db[dn];

      res.end();
      return next();
    });

    server.modify(SUFFIX, authorize, function(req, res, next) {
      var dn = req.dn.toString();
      if (!req.changes.length)
        return next(new ldap.ProtocolError('changes required'));
      if (!db[dn])
        return next(new ldap.NoSuchObjectError(dn));

      var entry = db[dn];

      for (var i = 0; i < req.changes.length; i++) {
        mod = req.changes[i].modification;
        switch (req.changes[i].operation) {
        case 'replace':
          if (!entry[mod.type])
            return next(new ldap.NoSuchAttributeError(mod.type));

          if (!mod.vals || !mod.vals.length) {
            delete entry[mod.type];
          } else {
            entry[mod.type] = mod.vals;
          }

          break;

        case 'add':
          if (!entry[mod.type]) {
            entry[mod.type] = mod.vals;
          } else {
            mod.vals.forEach(function(v) {
              if (entry[mod.type].indexOf(v) === -1)
                entry[mod.type].push(v);
            });
          }

          break;

        case 'delete':
          if (!entry[mod.type])
            return next(new ldap.NoSuchAttributeError(mod.type));

          delete entry[mod.type];

          break;
        }
      }

      res.end();
      return next();
    });

    server.search(SUFFIX, authorize, function(req, res, next) {
      var dn = req.dn.toString();
      if (!db[dn])
        return next(new ldap.NoSuchObjectError(dn));

      var scopeCheck;

      switch (req.scope) {
      case 'base':
        if (req.filter.matches(db[dn])) {
          res.send({
            dn: dn,
            attributes: db[dn]
          });
        }

        res.end();
        return next();

      case 'one':
        scopeCheck = function(k) {
          if (req.dn.equals(k))
            return true;

          var parent = ldap.parseDN(k).parent();
          return (parent ? parent.equals(req.dn) : false);
        };
        break;

      case 'sub':
        scopeCheck = function(k) {
          return (req.dn.equals(k) || req.dn.parentOf(k));
        };

        break;
      }

      Object.keys(db).forEach(function(key) {
        if (!scopeCheck(key))
          return;

        if (req.filter.matches(db[key])) {
          res.send({
            dn: key,
            attributes: db[key]
          });
        }
      });

      res.end();
      return next();
    });



    ///--- Fire it up

    server.listen(1389, function() {
      console.log('LDAP server up at: %s', server.url);
    });

# /etc/passwd server

    var fs = require('fs');
    var ldap = require('ldapjs');
    var spawn = require('child_process').spawn;



    ///--- Shared handlers

    function authorize(req, res, next) {
      if (!req.connection.ldap.bindDN.equals('cn=root'))
        return next(new ldap.InsufficientAccessRightsError());

      return next();
    }


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


    var pre = [authorize, loadPasswdFile];



    ///--- Mainline

    var server = ldap.createServer();

    server.bind('cn=root', function(req, res, next) {
      if (req.dn.toString() !== 'cn=root' || req.credentials !== 'secret')
        return next(new ldap.InvalidCredentialsError());

      res.end();
      return next();
    });


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
          return next(new ldap.OperationsError('' + code));

        res.end();
        return next();
      });
    });


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


    server.search('o=myhost', pre, function(req, res, next) {
      Object.keys(req.users).forEach(function(k) {
        if (req.filter.matches(req.users[k].attributes))
          res.send(req.users[k]);
      });

      res.end();
      return next();
    });



    // LDAP "standard" listens on 389, but whatever.
    server.listen(1389, '127.0.0.1', function() {
      console.log('/etc/passwd LDAP server up at: %s', server.url);
    });

# Address Book

This example is courtesy of [Diogo Resende](https://github.com/dresende) and
illustrates setting up an address book for typical mail clients such as
Thunderbird or Evolution over a MySQL database.

    // MySQL test: (create on database 'abook' with username 'abook' and password 'abook')
    //
    // CREATE TABLE IF NOT EXISTS `users` (
    //   `id` int(5) unsigned NOT NULL AUTO_INCREMENT,
    //   `username` varchar(50) NOT NULL,
    //   `password` varchar(50) NOT NULL,
    //   PRIMARY KEY (`id`),
    //   KEY `username` (`username`)
    // ) ENGINE=InnoDB  DEFAULT CHARSET=utf8;
    // INSERT INTO `users` (`username`, `password`) VALUES
    // ('demo', 'demo');
    // CREATE TABLE IF NOT EXISTS `contacts` (
    //   `id` int(5) unsigned NOT NULL AUTO_INCREMENT,
    //   `user_id` int(5) unsigned NOT NULL,
    //   `name` varchar(100) NOT NULL,
    //   `email` varchar(255) NOT NULL,
    //   PRIMARY KEY (`id`),
    //   KEY `user_id` (`user_id`)
    // ) ENGINE=InnoDB  DEFAULT CHARSET=utf8;
    // INSERT INTO `contacts` (`user_id`, `name`, `email`) VALUES
    // (1, 'John Doe', 'john.doe@example.com'),
    // (1, 'Jane Doe', 'jane.doe@example.com');
    //

    var ldap = require('ldapjs'),
        mysql = require("mysql"),
        server = ldap.createServer(),
        addrbooks = {}, userinfo = {},
        ldap_port = 389,
        basedn = "dc=example, dc=com",
        company = "Example",
        db = mysql.createClient({
          user: "abook",
          password: "abook",
          database: "abook"
        });

    db.query("SELECT c.*,u.username,u.password " +
             "FROM contacts c JOIN users u ON c.user_id=u.id",
             function(err, contacts) {
      if (err) {
        console.log("Error fetching contacts", err);
        process.exit(1);
      }

      for (var i = 0; i < contacts.length; i++) {
        if (!addrbooks.hasOwnProperty(contacts[i].username)) {
          addrbooks[contacts[i].username] = [];
          userinfo["cn=" + contacts[i].username + ", " + basedn] = {
            abook: addrbooks[contacts[i].username],
            pwd: contacts[i].password
          };
        }

        var p = contacts[i].name.indexOf(" ");
        if (p != -1)
          contacts[i].firstname = contacts[i].name.substr(0, p);

        p = contacts[i].name.lastIndexOf(" ");
        if (p != -1)
          contacts[i].surname = contacts[i].name.substr(p + 1);

        addrbooks[contacts[i].username].push({
          dn: "cn=" + contacts[i].name + ", " + basedn,
          attributes: {
            objectclass: [ "top" ],
            cn: contacts[i].name,
            mail: contacts[i].email,
            givenname: contacts[i].firstname,
            sn: contacts[i].surname,
            ou: company
          }
        });
      }

      server.bind(basedn, function (req, res, next) {
        var username = req.dn.toString(),
            password = req.credentials;

        if (!userinfo.hasOwnProperty(username) ||
             userinfo[username].pwd != password) {
          return next(new ldap.InvalidCredentialsError());
        }

        res.end();
        return next();
      });

      server.search(basedn, function(req, res, next) {
        var binddn = req.connection.ldap.bindDN.toString();

        if (userinfo.hasOwnProperty(binddn)) {
          for (var i = 0; i < userinfo[binddn].abook.length; i++) {
            if (req.filter.matches(userinfo[binddn].abook[i].attributes))
              res.send(userinfo[binddn].abook[i]);
          }
        }
        res.end();
      });

      server.listen(ldap_port, function() {
        console.log("Addressbook started at %s", server.url);
      });
    });

To test out this example, try:

    $ ldapsearch -H ldap://localhost:389 -x -D cn=demo,dc=example,dc=com \
      -w demo -b "dc=example,dc=com" objectclass=*
