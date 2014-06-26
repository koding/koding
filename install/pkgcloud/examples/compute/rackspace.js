var pkgcloud = require('pkgcloud'),
  _ = require('underscore');

// create our client with your rackspace credentials
var client = pkgcloud.providers.rackspace.compute.createClient({
  username: 'your-username',
  apiKey: 'your-api-key'
});

// first we're going to get our flavors
client.getFlavors(function (err, flavors) {
  if (err) {
    console.dir(err);
    return;
  }

  // then get our base images
  client.getImages(function (err, images) {
    if (err) {
      console.dir(err);
      return;
    }

    // Pick a 512MB instance flavor
    var flavor = _.findWhere(flavors, { name: '512MB Standard Instance' });

    // Pick an image based on Ubuntu 12.04
    var image = _.findWhere(images, { name: 'Ubuntu 12.04 LTS (Precise Pangolin)' });

    // Create our first server
    client.createServer({
      name: 'server1',
      image: image,
      flavor: flavor
    }, handleServerResponse);

    // Create our second server
    client.createServer({
      name: 'server2',
      image: image,
      flavor: flavor
    }, handleServerResponse);
  });
});

// This function will handle our server creation,
// as well as waiting for the server to come online after we've
// created it.
function handleServerResponse(err, server) {
  if (err) {
    console.dir(err);
    return;
  }

  console.log('SERVER CREATED: ' + server.name + ', waiting for active status');

  // Wait for status: ACTIVE on our server, and then callback
  server.setWait({ status: server.STATUS.running }, 5000, function (err) {
    if (err) {
      console.dir(err);
      return;
    }

    console.log('SERVER INFO');
    console.log(server.name);
    console.log(server.status);
    console.log(server.id);

    console.log('Make sure you DELETE server: ' + server.id +
      ' in order to not accrue billing charges');
  });
}