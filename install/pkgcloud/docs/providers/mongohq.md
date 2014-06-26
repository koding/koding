# Using MongoHQ with `pkgcloud`

MongoHQ is available in `pkgcloud` as a `pkgcloud.databases` target. Here is an example of how to use it:

``` js
  var client = pkgcloud.database.createClient({
    provider: 'mongohq',
    username: "bob",
    password: "1234"
  });

  //
  // Create a MongoDB
  //
  client.create({
    name: "mongo-instance",
    plan: "free",
  }, function (err, result) {
    //
    // Check the result
    //
    console.log(err, result);
  
    //
    // Now delete that same MongoDB
    //
    client.remove(result.id, function (err, result) {
      //
      // Check the result
      //
      console.log(err, result);
    });
  });
```

The `client` instance returned by `pkgcloud.database.createClient` has the following methods for MongoHQ:

* `client.create(options, callback)`
* `client.remove(id, callback)`