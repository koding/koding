# Using RedisToGo with `pkgcloud`

``` js
  var client = pkgcloud.database.createClient({
    provider: 'redistogo',
    username: "bob",
    password: "1234"
  });

  //
  // Create a redis
  //
  client.create({
    plan: "nano",
  }, function (err, result) {
    //
    // Log the result
    //
    console.log(err, result);
  
    //
    // Get the same redis we just created
    //
    client.get(result.id, function (err, result) {
      //
      // Show the details of the database we just created
      //
      console.log(err, result);
      client.remove(result.id, function (err, result) {
        //
        // Ensure it was removed correctly.
        //
        console.log(err, result);
      });
    });
  });
```

The `client` instance returned by `pkgcloud.database.createClient` has the following methods for RedisToGo:

* `client.create(options, callback)`
* `client.remove(id, callback)`
* `client.get(id, callback)`