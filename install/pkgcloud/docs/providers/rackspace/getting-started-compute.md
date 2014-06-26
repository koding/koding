# Getting started with pkgcloud & Rackspace

The Rackspace node.js SDK is available as part of `pkgcloud`, a multi-provider cloud provisioning package. In addition to the Rackspace provider, `pkgcloud` also has an OpenStack compute provider.

Pkgcloud currently supports Rackspace Next Generation Cloud Servers, Cloud Files, and Cloud Databases.

To install `pkgcloud` from the command line:

```
npm install pkgcloud
```

Don't have `npm` or `node` yet? [Get it now](http://nodejs.org/download).

## Using pkgcloud

In this example, we're going to create a Rackspace compute client, create two servers, and then output their details to the command line.

*Note: We're going to use [underscore.js](http://underscorejs.org) for some convenience functions.*

```Javascript
var pkgcloud = require('pkgcloud'),
    _ = require('underscore');

// create our client with your rackspace credentials
var client = pkgcloud.providers.rackspace.compute.createClient({
  username: 'your-username',
  apiKey:   'your-api-key'
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
    server.setWait({ status: 'ACTIVE' }, 5000, function (err) {
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
```