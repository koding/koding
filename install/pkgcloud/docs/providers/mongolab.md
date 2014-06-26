# Using MongoLab with `pkgcloud`

The MongoLab API has a slightly different approach for managing databases: they have implemented accounts, and each account can provision databases. **To create a database with MongoLab you will need first create an account and then use the created account as "owner" of the database.**

``` js
  //
  // First lets set up the client
  //
  var client = pkgcloud.database.createClient({
    provider: 'mongolab',
    username: 'bob',
    password: '1234'
  });
```

``` js
  //
  // Now lets create an account
  // name and email are required fields.
  //
  client.createAccount({
    name:'daniel',
    email:'daniel@nodejitsu.com',
    //
    // If you want, you can set your own password 
    // (Password must contain at least one numeric character.)
    // if not mongolab will create a password for you.
    //
    password:'mys3cur3p4ssw0rd'
  }, function (err, user) {
    //
    // Now you can provision databases under this user account
    //
    console.log(user);
  });
```

``` js
  //
  // Now lets create a database
  // name and owner are required fields
  //
  client.create({
    name:'myDatabase',
    //
    // You need to put the exact name account returned in the account creation.
    //
    owner: user.account.username
  }, function (err, database) {
    //
    // That is all
    //
    console.log(database);
  });
```

The `client` instance returned by `pkgcloud.database.createClient` has the following methods for MongoLab:

## Accounts
* `client.createAccount(options, callback)`
* `client.getAccounts(callback)`
* `client.getAccount(name, callback)`
* `client.deleteAccount(name, callback)`

## Databases
* `client.create(options, callback)`
* `client.getDatabases(owner, callback)`
* `client.getDatabase(options, callback)`
* `client.remove(options, callback)`