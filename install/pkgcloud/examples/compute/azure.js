var pkgcloud = require('../../lib/pkgcloud'),
  fs = require('fs'),
  client,
  options;

//
// Create a pkgcloud compute instance
//
options = {
  provider: 'azure',
  "storageAccount": "test-storage-account",
  "storageAccessKey": "test-storage-access-key",
  "subscriptionId": "azure-account-subscription-id",
  key: fs.readFileSync('path to your account management key file', 'ascii'),
  cert: fs.readFileSync('path to your account management certificate pem file', 'ascii')
};
client = pkgcloud.compute.createClient(options);

//
// Create a server.
// This may take several minutes.
//
options = {
  // pkgcloud compute properties
  name:  'pkgcloud-test',   // name of the server
  flavor: 'ExtraSmall',     // azure vm size
  image: '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS63DEC20121220', // OS Image to use

  // Azure vm properties
  location:  'East US',       // Azure location for server
  username:  'pkgcloud',      // Username for server
  password:  'Pkgcloud!!',    // Password for server

  // Azure linux SSH properties
  ssh: {
    cert: fs.readFileSync('path to your ssh pem file', 'ascii')
  },

  // Azure ports (endpoints)
  ports: [
    {
      name : "foo",             // name of port
      protocol : "tcp",         // tcp or udp
      port: "12333",           // external port number
      localPort: "12333"       // internal port number
    }
  ]
};

console.log("creating server...");

client.createServer(options, function (err, server) {
  if (err) {
    console.log(err);
  } else {
    // Wait for the server to reach the RUNNING state.
    // This may take several minutes.
    console.log("waiting for server RUNNING state...");
    server.setWait({ status: server.STATUS.running }, 10000, function (err, server) {
      if (err) {
        console.log(err);
      } else {
        console.dir(server);
      }
    });
  }
});



