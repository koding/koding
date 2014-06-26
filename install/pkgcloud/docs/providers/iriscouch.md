# Using IrisCouch with `pkgcloud`

**In order to use IrisCOuch you will need to have created a valid account.** IrisCouch actually exposes two database services:

* [Using CouchDB](#couchdb)
* [Using Redis](#redis)
* [All API Methods](#all-api-methods)

<a name="couchdb"></a>
## Using CouchDB

``` js
var client = pkgcloud.database.createClient({
  provider: 'iriscouch',
  username: 'bob',
  password: '1234'
});

//
// Create a couch
//
client.create({
  subdomain:  'pkgcloud-nodejitsu-test-7',
  first_name: 'pkgcloud',
  last_name:  'pkgcloud',
  email:      'info@nodejitsu.com'
}, function (err, result) {
  //
  // Check now exists @ http://pkgcloud-nodejitsu-test-7.iriscouch.com
  //
  console.log(err, result);
});
```

<a name="redis"></a>
## Using Redis

IrisCouch also supports provisioning redis databases. In this case just pass the option `type: 'redis'` to the `create()` method and put a `password` for the access.

``` js
//
// Crate a redis database
//
client.create({
  subdomain: 'pkgcloud-nodejitsu-test-7',
  first_name: 'pkgcloud',
  last_name: 'pkgcloud',
  email: 'info@nodejitsu.com',
  //
  // For redis instead of couch just put type to redis
  //
  type: 'redis',
  //
  // AND ADD A PASSWORD! (required)
  //
  password: 'mys3cur3p4ssw0rd'
}, function (err, result) {
  //
  // Check the connection, use result.host and result.password values
  //  redis-cli -h $RESULT.HOST -a $RESULT.PASSWORD
  //
  console.log('HOST to connect:', result.host);
  console.log('KEY to use:', result.password);
});
```

## All API methods

The `client` instance returned by `pkgcloud.database.createClient` has the following methods for IrisCouch:

* `client.create(options, callback)`