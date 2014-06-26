var pkgcloud = require('../../lib/pkgcloud');

//
// Joyent requires a username / password or key / keyId combo.
// key/keyId should be registered in Joyent servers.
// check `test/helpers/index.js` for details on key/keyId works.
//
var client = pkgcloud.compute.createClient({
  provider: 'joyent',
  account: 'nodejitsu',
  keyId: '/nodejitsu1/keys/dscape',
  key: fs.readFileSync(path.join(process.env.HOME, '.ssh/id_rsa'), 'ascii')
});

//
// Alternatively create a client with a username / password pair
//
var otherClient = pkgcloud.compute.createClient({
  provider: 'joyent',
  username: 'your-account', 
  password: 'your-password'
});

