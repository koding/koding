##Using the Rackspace Database provider

Creating a client is straight-forward:

``` js
  var rackspace = pkgcloud.database.createClient({
    provider: 'rackspace',
    username: 'your-user-name',
    apiKey: 'your-api-key'
  });
```

[More options for creating clients](README.md)

### Creating a MySQL Database

The steps for provision a MySQL database from rackspace cloud databases are:

1. Choose a flavor (memory RAM size)
2. Create an instance of a database server.
3. When the instance is provisioned, create your database.

Also you can manage users across your instances and each instance can handle several databases.

``` js
  client.getFlavors(function (err, flavors) {
    //
  	// Look at the availables flavors for your instance
  	//
  	console.log(flavors);

  	//
    // Lets choose the ID 1 for 512MB flavor
    //
    client.getFlavor(1, function (err, flavor) {
      //
      // Create the instance for host the databases.
      //
      client.createInstance({
        name: 'test-instance',
        flavor: flavor,
        //
        // Optional, you can choose the disk size for the instance
        // (1 - 8) in GB. Default to 1
        //
        size: 3
        //
        // Optional, you can give an array of database names for initialize
        // when the instace is ready
        //
        databases: ['first-database', 'second-database']
      }, function (err, instance) {
        //
        // At this point when the instance is ready we can manage the databases
        //
        client.createDatabase({
          name: 'test-database',
          instance: instance
        }, function (err, database) {
          //
          // Log the result
          //
          console.log(database);
        });
      });
    })
  });
```

### API Methods ###

#### client.createUser(options, callback)

Allows the creation of specific users to have access to any database you create.

Accepts one user object as the `options` argument or an array of user objects.

A user object is defined as follows:

```js
{
  username: 'nodejitsu',              // required
  password: 'foobar',                 // required
  databases: ['first-db, second-db'], // required (Can be either string or array)
  instance: instance                  // required (instance or instanceId)
}
```

**note**: If creating multiple users, the instance provided must be the same for
both.