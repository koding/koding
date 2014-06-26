var pkgcloud = require('pkgcloud'),
  _ = require('underscore');

(function() {

  var config = {
    username: 'your-username',
    apiKey: 'your-api-key',
    region: 'DFW'
  };

  // create our client with your rackspace credentials
  var computeClient = pkgcloud.providers.rackspace.compute.createClient(config);
  var blockStorageClient = pkgcloud.providers.rackspace.blockstorage.createClient(config);

  // first we're going to get our flavors
  computeClient.getFlavors(function (err, flavors) {
    if (err) {
      console.dir(err);
      return;
    }

    // then get our base images
    computeClient.getImages(function (err, images) {
      if (err) {
        console.dir(err);
        return;
      }

      // Pick a 512MB instance flavor
      var flavor = _.findWhere(flavors, { name: '512MB Standard Instance' });

      // Pick an image based on Ubuntu 12.04
      var image = _.findWhere(images, { name: 'Ubuntu 12.04 LTS (Precise Pangolin)' });

      // Create our first server
      computeClient.createServer({
        name: 'server1',
        image: image,
        flavor: flavor
      }, function(err, server) {
        if (err) {
          console.error(err);
          return;
        }

        // Wait for our server to start up
        server.setWait({ status: server.STATUS.running }, 5000, function (err) {
          if (err) {
            console.dir(err);
            return;
          }

          // create a block storage volume
          blockStorageClient.createVolume({
            name: 'my-volume',
            description: 'my volume description',
            size: 100,
            volumeType: 'SATA'
          }, function(err, volume) {
            if (err) {
              console.error(err);
              return;
            }

            // finally attach the volume to our newly created server
            computeClient.attachVolume(server, volume, function(err, attachment) {
              if (err) {
                console.error(err);
              }

              console.dir(attachment);
            });
          });
        });
      });
    });
  });
})();
