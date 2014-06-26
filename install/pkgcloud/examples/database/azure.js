var pkgcloud = require('../../lib/pkgcloud');

var client = pkgcloud.database.createClient({
  provider: 'azure',
  storageAccount: "storage-account-name",        // Name of your Azure storage account
  storageAccessKey: "storage-account-access-key" // Access key for storage account
});

//
// Create an Azure Table
//
client.create({
  name: "testing123"
}, function (err, result) {
  //
  // Check the result
  //
  console.log(err, result);

  //
  // Now delete that same Azure Table
  //
  if (err === null) {
    client.remove(result.id, function (err, result) {
      //
      // Check the result
      //
      console.log(err, result);
    });
  }
});

// Use the azure-sdk-for-node to create, query, insert, update, merge, and delete Table entities.
// For more info: https://github.com/WindowsAzure/azure-sdk-for-node

