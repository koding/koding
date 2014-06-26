var pkgcloud = require('../../lib/pkgcloud');

var client = pkgcloud.database.createClient({
  provider: 'iriscouch',
  username: "bob",
  password: "1234"
});

//
// Create a couch database
//
client.create({
  subdomain: "pkgcloud-nodejitsu-test-5",
  first_name: "pkgcloud",
  last_name: "pkgcloud",
  email: "info@nodejitsu.com"
}, function (err, result) {
  //
  // Check now exists @ http://pkgcloud-nodejitsu-test-5.iriscouch.com
  //
  console.log(err, result);
});

//
// Crate a redis database
//
client.create({
  subdomain: "pkgcloud-nodejitsu-test-6",
  first_name: "pkgcloud",
  last_name: "pkgcloud",
  email: "info@nodejitsu.com",
  //
  // For redis instead of couch just put type to redis
  //
  type: "redis",
  //
  // AND ADD A PASSWORD! (required)
  //
  password: "mys3cur3p4ssw0rd"
}, function (err, result) {
  //
  // Check the connection, use result.host and result.password values
  //  redis-cli -h $RESULT.HOST -a $RESULT.PASSWORD
  //
  console.log('HOST to connect:', result.host);
  console.log('KEY to use:', result.password);
});