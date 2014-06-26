/*
 * network.js: Base network from which all pkgcloud networks inherit.
 *
 * (C) 2014 Hewlett-Packard Development Company, L.P.
 *
 */

var utile = require('utile'),
    model = require('../base/model');

var Network = exports.Network = function (client, details) {
  model.Model.call(this, client, details);
};

utile.inherits(Network, model.Model);

Network.prototype.create = function (callback) {
  this.client.createNetwork(this.name, callback);
};

Network.prototype.refresh = function (callback) {
  this.client.getNetwork(this.id, callback);
};

Network.prototype.update = function (callback) {
  this.client.updateNetwork(this, callback);
};

Network.prototype.destroy = function (callback) {
  this.client.destroyNetwork(this.id, callback);
};
