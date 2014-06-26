/*
 * servers.js: Instance methods for working with servers from DigitalOcean
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */
var request  = require('request'),
    base     = require('../../../core/compute'),
    pkgcloud = require('../../../../../lib/pkgcloud'),
    errs     = require('errs'),
    compute  = pkgcloud.providers.digitalocean.compute;

//
// ### function getVersion (callback)
// #### @callback {function} f(err, version).
//
// Gets the current API version
//
exports.getVersion = function getVersion(callback) {
  return errs.handle(
    errs.create({ message: "DigitalOcean's API does not support versioning" }),
    callback
  );
};

//
// ### function getLimits (callback)
// #### @callback {function} f(err, version).
//
// Gets the current API limits
//
exports.getLimits = function getLimits(callback) {
  return errs.handle(
    errs.create({ message: "DigitalOcean's API is not rate limited" }),
    callback
  );
};

//
// ### function getServers (callback)
// #### @options {Object} Options when getting servers
// ####   @options.offset {number} Number of servers to skip when listing
// ####   @options.limit  {number} Number of servers to return
// #### @callback {function} f(err, servers). `servers` is an array that
// represents the servers that are available to your account
//
// Lists all servers available to your account.
//
exports.getServers = function getServers(options, callback) {
  if (!callback && typeof options === 'function') {
    callback = options;
    options = null;
  }

  var self = this;
  return this._request(
    {
      path: '/droplets',
      qs: options
    },
    function (err, body, res) {
      if (err) {
        return callback(err);
      }

      callback(null, body.droplets.map(function (result) {
        return new compute.Server(self, result);
      }), res);
    }
  );
};

//
// ### function createServer (options, callback)
// #### @opts {Object} **Optional** options
// ####    @name     {String} **Optional** a name for your server
// ####    @flavor   {String|Flavor} **Optional** flavor to use for this image
// ####    @image    {String|Image} **Optional** the image to use
// ####    @required {Boolean} **Optional** Validate if flavor, name,
// and image are present
// ####    @*        {*} **Optional** Anything platform specific
// #### @callback {Function} f(err, server).
//
// Creates a server with the specified options. The flavor
// properties of the options can be instances of Flavor
// OR ids to those entities in DigitalOcean.
//
exports.createServer = function createServer(options, callback) {
  if (typeof options === 'function') {
    callback = options;
    options  = {};
  }

  options = options || {}; // no args

  var self = this,
      createOptions = {
        path: '/droplets/new',
        qs: {}
      };

  ['flavor', 'image', 'name'].forEach(function (member) {
    if (!options[member]) {
      return errs.handle(
        errs.create({ message: 'options.' + member + ' is a required argument.' }),
        callback
      );
    }
  });

  createOptions.qs.name      = options.name;
  createOptions.qs.region_id = options.region || options.region_id || 1;
  createOptions.qs.size_id   = options.flavor instanceof base.Flavor
    ? options.flavor.id
    : options.flavor;

  createOptions.qs.image_id = options.image instanceof base.Image
    ? options.image.id
    : options.image;

  //
  // Integrate with existing keys API, but support keyNames as well
  // which can be a single string or an Array.
  //
  if (options.keyname) {
    createOptions.qs.ssh_key_ids = options.keyname;
  }
  else if (options.keynames) {
    createOptions.qs.ssh_key_ids = Array.isArray(options.keynames)
      ? options.keynames.join(',')
      : options.keynames;
  }

  return this._request(createOptions, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, new compute.Server(self, body.droplet), res);
  });
};

//
// ### function destroyServer(server, callback)
// #### @server {Server|String} Server id or a server
// #### [@options] {object} Pass optioos for deletion
// #### [options.scrubData] Optionally disable scrubbing data (boolean),
//        default (true) is to scrub data from Digital Ocean servers
//
// #### @callback {Function} f(err, serverId).
//
// Destroy a server in DigitalOcean.
//
exports.destroyServer = function destroyServer(server, options, callback) {
  var serverId = server instanceof base.Server ? server.id : server,
      self = this;

  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  this._request({
    path: '/droplets/' + serverId + '/destroy',
    qs: {
      scrub_data: (typeof options.scrubData === 'boolean')
        ? (options.scrubData ? '1' : '0')
        : '1'
    }
  }, function (err, body, res) {
    return err ? callback(err) : callback(null, { ok: serverId }, res);
  });
};

//
// ### function getServer(server, callback)
// #### @server {Server|String} Server id or a server
// #### @callback {Function} f(err, serverId).
//
// Gets a server in DigitalOcean.
//
exports.getServer = function getServer(server, callback) {
  var serverId = server instanceof base.Server ? server.id : server,
      self     = this;

  return this._request({
    path: '/droplets/' + serverId
  }, function (err, body, res) {
    return !err
      ? callback(null, new compute.Server(self, body.droplet), res)
      : callback(err);
  });
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
  return this._request({
    path: '/droplets/' + serverId + '/reboot'
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, { ok: serverId }, res);
  });
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
  var serverId = server instanceof base.Server ? server.id : server;
  return this._request({
    path: '/droplets/' + serverId + '/rename',
    qs: { name: name }
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, { ok: serverId }, res);
  });
};
