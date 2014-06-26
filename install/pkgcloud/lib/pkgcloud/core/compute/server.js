/*
 * server.js: Base server from which all pkgcloud servers inherit from
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    model = require('../base/model'),
    computeStatus = require('../../common/status').compute;

var Server = exports.Server = function (client, details) {
  model.Model.call(this, client, details);
};

utile.inherits(Server, model.Model);

Server.prototype.refresh = function (callback) {
  var self = this;
  return self.client.getServer(this, function (err, server) {
    if (!err) self._setProperties(server.original);
    return callback.apply(this, arguments);
  });
};

Server.prototype.create = function (callback) {
  return this.client.createServer(this, callback);
};

Server.prototype.destroy = function (callback) {
  return this.client.destroyServer(this, callback);
};

Server.prototype.reboot = function (callback) {
  return this.client.rebootServer(this, callback);
};

Server.prototype.resize = function () {
  var args = [this].concat(Array.prototype.slice.call(arguments));
  this.client.resizeServer.apply(this.client, args);
};

Server.prototype.STATUS = computeStatus;