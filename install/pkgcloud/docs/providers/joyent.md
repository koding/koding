# Using Joyent with `pkgcloud`

* [Using Compute](#using-compute)

<a name="using-compute"></a>
## Using Compute

Joyent requires a username / password or key / keyId combo. The key / keyId should be registered in Joyent servers; check `test/helpers/index.js` for details on key/keyId works.

**key / keyId pair**
``` js
  var pkgcloud = require('pkgcloud'),
      path = require('path'),
      fs   = require('fs');

  var joyent = pkgcloud.compute.createClient({
    provider: 'joyent',
    account: 'nodejitsu'
    keyId: '/nodejitsu1/keys/dscape',
    key: fs.readFileSync(path.join(process.env.HOME, '.ssh/id_rsa'), 'ascii')
  });
```

**username / password**
``` js
  var pkgcloud = require('pkgcloud');
  
  var joyent = pkgcloud.compute.createClient({
    provider: 'joyent',
    username: 'your-account', 
    password: 'your-password'
  });
```