var pkgcloud = require('../../lib/pkgcloud');

var azure = pkgcloud.storage.createClient({
  provider: 'azure',
  storageAccount: "test-storage-account",     // Name of your storage account
  storageAccessKey: "test-storage-access-key" // Access key for storage account
});
