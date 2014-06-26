/*
 * servers.js: Instance methods for working with servers from AWS Cloud
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */
var async = require('async'),
    request  = require('request'),
    base     = require('../../../core/compute'),
    pkgcloud = require('../../../../../lib/pkgcloud'),
    errs     = require('errs'),
    compute  = pkgcloud.providers.amazon.compute;

//
// ### function getVersion (callback)
// #### @callback {function} f(err, version).
//
// Gets the current API version
//
exports.getVersion = function getVersion(callback) {
  var self = this;
  process.nextTick(function() {
    callback(null, self.version);
  });
};

//
// ### function getLimits (callback)
// #### @callback {function} f(err, version).
//
// Gets the current API limits
//
exports.getLimits = function getLimits(callback) {
  return errs.handle(
    errs.create({ message: "AWS's API is not rate limited" }),
    callback
  );
};

//
// ### function _getDetails (details, callback)
// #### @details {Object} Short details of server
// #### @callback {function} f(err, details) Amended short details.
//
// Loads IP and name of server.
//
exports._getDetails = function getDetails(details, callback) {
  var self = this;

  self._query(
    'DescribeInstanceAttribute', {
      InstanceId: details.instanceId,
      Attribute: 'userData'
    },
    function (err, body, res) {
      if (err) {
        // disregard the errors, if any
        return callback(null, details);
      }

      var meta = new Buffer(
        body.userData.value || '',
        'base64'
      ).toString();

      try {
        meta = JSON.parse(meta);
      } catch (e) {
        meta = {};
      }

      details.name = meta.name;
      callback(null, details);
    });
};

//
// ### function getServers (callback)
// #### @callback {function} f(err, servers). `servers` is an array that
// represents the servers that are available to your account
//
// Lists all servers available to your account.
//
exports.getServers = function getServers(callback) {
  var self = this;
  return self._query('DescribeInstances', {}, function (err, body, res) {
    if (err) {
      return callback(err);
    }

    var servers = [];

    if (!body || !body.reservationSet || !body.reservationSet.item) {
      return callback(null, []);
    }

    self._toArray(body.reservationSet.item).forEach(function (reservation) {
      self._toArray(reservation.instancesSet.item).forEach(function (instance) {
        servers.push(instance);
      });
    });

    async.map(
      servers,
      self._getDetails.bind(self),
      function finish(err, servers) {
        return err
          ? callback(err)
          : callback(null, servers.map(function (server) {
              return new compute.Server(self, server);
            }), res);
      }
    );
  });
};

//
// ### function createServer (options, callback)
// #### @opts {Object} **Optional** options
// ####    @name     {String} **Optional** the name of server
// ####    @image    {String|Image} the image (AMI) to use
// ####    @flavor   {String|Flavor} **Optional** flavor to use for this image
// #### @callback {Function} f(err, server).
//
// Creates a server with the specified options. The flavor
// properties of the options can be instances of Flavor
// OR ids to those entities in AWS.
//
exports.createServer = function createServer(options, callback) {
  if (typeof options === 'function') {
    callback = options;
    options  = {};
  }

  options = options || {}; // no args
  var self = this,
      meta = { name: options.name || '' },
      createOptions = {
        UserData: new Buffer(JSON.stringify(meta)).toString('base64'),
        MinCount: 1,
        MaxCount: 1
      },
      securityGroup,
      securityGroupId;

  if (!options.image) {
    return errs.handle(
      errs.create({
        message: 'options.image is a required argument.'
      }),
      callback
    );
  }

  securityGroup = this.securityGroup || options['SecurityGroup'];
  if (securityGroup) {
    createOptions['SecurityGroup'] = securityGroup;
  }

  securityGroupId = this.securityGroupId || options['SecurityGroupId'];
  if (securityGroupId) {
    createOptions['SecurityGroupId'] = securityGroupId;
  }

  createOptions.ImageId = options.image instanceof base.Image
    ? options.image.id
    : options.image;

  if (options.flavor) {
    createOptions.InstanceType = options.flavor instanceof base.Flavor
      ? options.flavor.id
      : options.flavor;
  }

  if (options.keyname || options.KeyName) {
    createOptions.KeyName = options.keyname || options.KeyName;
  }

  if (options.zone || options['Placement.AvailabilityZone']) {
    createOptions['Placement.AvailabilityZone'] = options.zone
      || options['Placement.AvailabilityZone'];
  }

  return this._query(
    'RunInstances',
    createOptions,
    function (err, body, res) {
      var server;
      if (err) {
        return callback(err);
      }

      self._toArray(body.instancesSet.item).forEach(function (instance) {
        instance.meta = meta;
        server = new compute.Server(self, instance);
      });

      callback(null, server, res);
    }
  );
};

//
// ### function destroyServer(server, callback)
// #### @server {Server|String} Server id or a server
// #### @callback {Function} f(err, serverId).
//
// Destroy a server in AWS.
//
exports.destroyServer = function destroyServer(server, callback) {
  var serverId = server instanceof base.Server ? server.id : server;

  return this._query(
    'TerminateInstances',
    { InstanceId: serverId },
    function (err, body, res) {
      return err
        ? callback && callback(err)
        : callback && callback(null, { ok: serverId }, res);
    }
  );
};

//
// ### function getServer(server, callback)
// #### @server {Server|String} Server id or a server
// #### @callback {Function} f(err, serverId).
//
// Gets a server in AWS.
//
exports.getServer = function getServer(server, callback) {
  var self     = this,
      serverId = server instanceof base.Server ? server.id : server;

  return this._query(
    'DescribeInstances',
    {
      'InstanceId.1' : serverId,
      'Filter.1.Name': 'instance-state-code',
      'Filter.1.Value.1': 0, // pending
      'Filter.1.Value.2': 16, // running
      'Filter.1.Value.3': 32, // shutting down
      'Filter.1.Value.4': 64, // stopping
      'Filter.1.Value.5': 80 // stopped
    },
    function (err, body, res) {
      var server;

      if (err) {
        return callback(err);
      }

      self._toArray(body.reservationSet.item).forEach(function (reservation) {
        self._toArray(reservation.instancesSet.item).forEach(function (instance) {
          server = instance;
        });
      });

      if (server === undefined) {
        return callback(new Error('Server not found'));
      }

      self._getDetails(server, function (err, server) {
        if (err) return callback(err);
        callback(null, new compute.Server(self, server));
      });
    }
  );
};


//
// ### function rebootServer (server, options, callback)
// #### @server   {Server|String} The server to reboot
// #### @callback {Function} f(err, server).
//
// Reboots a server
//
exports.rebootServer = function rebootServer(server, callback) {
  var serverId = server instanceof base.Server ? server.id : server;

  return this._query(
    'RebootInstances',
    { InstanceId: serverId },
    function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, { ok: serverId }, res);
    }
  );
};

//
// ### function renameServer(server, name, callback)
// #### @server {Server|String} Server id or a server
// #### @name   {String} New name to apply to the server
// #### @callback {Function} f(err, server).
//
// Renames a server
//
exports.renameServer = function renameServer(server, name, callback) {
  return errs.handle(
    errs.create({ message: 'Not supported by AWS.' }),
    callback
  );
};
