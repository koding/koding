ldapjs makes the LDAP protocol a first class citizen in Node.js.

## Usage

For full docs, head on over to <http://ldapjs.org>.

    var ldap = require('ldapjs');

    var server = ldap.createServer();

    server.search('dc=example', function(req, res, next) {
      var obj = {
        dn: req.dn.toString(),
        attributes: {
          objectclass: ['organization', 'top'],
              o: 'example'
        }
      };

      if (req.filter.matches(obj.attributes))
        res.send(obj);

      res.end();
    });

    server.listen(1389, function() {
      console.log('ldapjs listening at ' + server.url);
    });

To run that, assuming you've got the [OpenLDAP](http://www.openldap.org/) client
on your system:

    ldapsearch -H ldap://localhost:1389 -x -b dc=example objectclass=*

## Installation

    npm install ldapjs

## License

MIT.

## Bugs

See <https://github.com/mcavage/node-ldapjs/issues>.
