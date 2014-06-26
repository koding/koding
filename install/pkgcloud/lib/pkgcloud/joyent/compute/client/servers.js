/*
 * servers.js: Instance methods for working with servers from Joyent Cloud
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */
var request  = require('request'),
    base     = require('../../../core/compute'),
    pkgcloud = require('../../../../../lib/pkgcloud'),
    errs     = require('errs'),
    compute  = pkgcloud.providers.joyent.compute;

//
// ### function getVersion (callback)
// #### @callback {function} f(err, version).
//
// Gets the current API version
//
exports.getVersion = function getVersion(callback) {
  return this._request({
    path: this.account + '/datacenters'
  }, function (err, response, res) {
      return err
        ? callback(err)
        : callback(null, res.headers['x-api-version'], res);
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
    errs.create({message: "Joyent's API is not rate limited"}), callback);
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
      path: this.account + '/machines',
      qs: options
    },
    function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, body.map(function (result) {
            return new compute.Server(self, result);
          }), res);
    }
  );
};

//
// ### function createServer (options, callback)
// #### @opts {Object} **Optional** options
// ####    @name     {String} **Optional** a name for your server
// ####    @flavor   {String|Favor} **Optional** flavor to use for this image
// ####    @image    {String|Image} **Optional** the image to use
// ####    @required {Boolean} **Optional** Validate if flavor, name,
// and image are present
// ####    @*        {*} **Optional** Anything platform specific
// #### @callback {Function} f(err, server).
//
// Creates a server with the specified options. The flavor
// properties of the options can be instances of Flavor
// OR ids to those entities in Joyent.
//
exports.createServer = function createServer(options, callback) {
  if (typeof options === 'function') {
    callback = options;
    options  = {};
  }

  options = options || {}; // no args
  var self = this,
      createOptions = {
        method: 'POST',
        path:   this.account + '/machines',
        body:   options
      };

  ['flavor', 'image', 'name'].forEach(function (member) {
    if (options.required) { // marked as required?
      if (!options[member]) {
        return errs.handle(
          errs.create({ message: 'options.' + member + ' is a required argument.' }),
          callback
        );
      }
    }
  });
  if (options.flavor) {
    createOptions.body["package"] = options.flavor instanceof base.Flavor
      ? options.flavor.id
      : options.flavor;

    delete options.flavor;
  }

  if (options.image) {
    createOptions.body.dataset = options.image instanceof base.Image
      ? options.image.id
      : options.image;

    delete options.image;
  }

  return this._request(createOptions, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, new compute.Server(self, body), res);
  });
};

//
// ### function destroyServer(server, callback)
// #### @server {Server|String} Server id or a server
// #### @callback {Function} f(err, serverId).
//
// Destroy a server in Joyent.
//
exports.destroyServer = function destroyServer(server, callback) {
  var serverId = server instanceof base.Server ? server.id : server;
  var self = this;

  var stopOptions = {
    method: 'POST',
    path: this.account + '/machines/' + serverId,
    body: {
      action: 'stop'
    }
  };

  return this._request(stopOptions, function (err, body, res) {
    if (err) { return callback && callback(err); }
    if (res.statusCode === 202) {
      var checks = 10;
      var done = false;
      function check() {
        if (done) return;
        checks--;
        if (checks <= 0) return;
        if (checks === 0) {
          done = true;
          finish(new Error('Machine unresponsive to STOP'));
          return;
        }
        var checkOptions = {
          method: 'GET',
          path: self.account + '/machines/' + serverId
        };

        self._request(checkOptions, function (err, body, res) {
          if (err) { return callback && callback(err) }
          if (body && body.state === 'stopped') {
            done = true;
            finish();
            return;
          }
        });

        setTimeout(check, 5000);
      }

      check();
      return;
    }
    else {
      finish();
    }

    function finish() {
      var destroyOptions = {
        method: 'DELETE',
        path: self.account + '/machines/' + serverId
      };

      self._request(destroyOptions,  function (err, body, res) {
        return err
          ? callback && callback(err)
          : callback && callback(err, {ok: serverId}, res);
      });
    }
  });
};

//
// ### function getServer(server, callback)
// #### @server {Server|String} Server id or a server
// #### @callback {Function} f(err, serverId).
//
// Gets a server in Joyent.
//
exports.getServer = function getServer(server, callback) {
  var self     = this,
      serverId = server instanceof base.Server ? server.id : server;

  return this._request({
      path: this.account + '/machines/' + serverId
    }, function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, new compute.Server(self, body), res);
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
  var createOptions = {
    method: 'POST',
    path: this.account + '/machines/' + serverId,
    qs: {
      action: 'reboot'
    }
  };

  return this._request(createOptions, function (err, body, res) {
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
  return errs.handle(
    errs.create({ message: 'Not supported by Joyent.' }),
    callback
  );
};