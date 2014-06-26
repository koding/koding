var pkgcloud = require('../../lib/pkgcloud');

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