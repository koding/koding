![HP Helion icon](http://www8.hp.com/hpnext/sites/default/files/content/documents/HP%20Helion%20Logo_Cloud_Martin%20Fink_New%20Style%20of%20IT_Hewlett-Packard.PNG)
# Getting started with pkgcloud & HP Helion Cloud
The HP node.js SDK is available as part of `pkgcloud`, a multi-provider cloud provisioning package

Pkgcloud currently supports HP Helion Cloud Compute and HP Helion Cloud Object Storage, and HP Helion Cloud Networking.

To install `pkgcloud` from the command line:

```
npm install pkgcloud
```

Don't have `npm` or `node` yet? [Get it now](http://nodejs.org/download).

## Using pkgcloud

In this example, we're going to create a HP Helion Cloud Compute client, create two servers, and then output their details to the command line.

*Note: We're going to use [underscore.js](http://underscorejs.org) for some convenience functions.*

```Javascript
var pkgcloud = require('pkgcloud'),
    _ = require('underscore');

// create our client with your openstack credentials
var client = pkgcloud.compute.createClient({
  provider: 'hp',
  username: 'your-user-name',
  apiKey: 'your-api-key',
  region: 'region of identity service',
  authUrl: 'https://your-identity-service'
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

         // Pick a medium instance flavor
         // see here for more instance flavors: http://www.hpcloud.com/products-services/hp-cloud-compute-13_5
        var flavor = _.findWhere(flavors, { name: 'standard.medium' });

        // Pick an image based on CentOS 6.3
        var image = _.findWhere(images, { name: 'CentOS 6.3 Server 64-bit 20130116' });

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
