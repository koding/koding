/*
 * networks.js: Instance methods for working with networks
 * for Openstack networking
 *
  * (C) 2014 Hewlett-Packard Development Company, L.P.
 *
 */

var async = require('async'),
    request = require('request'),
    pkgcloud = require('../../../../pkgcloud'),
    urlJoin = require('url-join'),
    _ = require('underscore');

/**
 * client.getNetworks
 *
 * @description get the list of networks for an account
 *
 * @param {object|Function}   options
 * @param {Function}          callback
 */
exports.getNetworks  = function (options, callback) {
  var self = this;

  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  var getNetworkOpts = {
    path: '/v2.0/networks'
  };

  this._request(getNetworkOpts, function (err, body) {
    if (err) {
      return callback(err);
    }
    else if (!body || !body.networks || !(body.networks instanceof Array)) {
      return new Error('Malformed API Response');
    }

    return callback(null, body.networks.map(function (network) {
      return new self.models.Network(self, network);
    }));
  });
};

/**
 * client.getNetwork
 *
 * @description get the details for a specific network
 *
 * @param {String|object}     network     the network or networkId
 * @param callback
 */
exports.getNetwork = function (network, callback) {
  var networkId = network instanceof this.models.Network ? network.id : network,
    self = this;
  self.emit('log::trace', 'Getting details for network', networkId);
  this._request({
    path: urlJoin('/v2.0/networks', networkId),
    method: 'GET'
  }, function (err, body, res) {
    if (err) {
      return callback(err);
    }

    if (!body ||!body.network) {
      return new Error('Malformed API Response');
    }

    callback(null, new self.models.Network(self, body.network));
  });
};

/**
 * client.createNetwork
 *
 * @description create a new network
 *
 * @param {object}    options
 * @param {String}    options.name      the name of the new network
 * @param callback
 */
exports.createNetwork = function (options, callback) {
  var network = typeof options === 'object' ? options : { 'name' : options},
      self = this;

  network = _convertNetworkToWireFormat(network);

  var createNetworkOpts = {
    method: 'POST',
    path: '/v2.0/networks',
    body: { 'network' : network}
  };

  self.emit('log::trace', 'Creating network', network);
  this._request(createNetworkOpts, function (err,body) {
    return err
      ? callback(err)
      : callback(null, new self.models.Network(self, body.network));
  });
};

/**
 * client.updateNetwork
 *
 * @description update an existing network
 *
 * @param {object}    options
 * @param callback
 */
exports.updateNetwork = function (network, callback) {
  var self = this,
  networkId = network.id,
  networkToUpdate = _convertNetworkToWireFormat(network);

  var updateNetworkOpts = {
    method: 'PUT',
    path: urlJoin('/v2.0/networks', networkId),
    contentType: 'application/json',
    body: { 'network' : networkToUpdate}
  };

  self.emit('log::trace', 'Updating network', networkId);
  this._request(updateNetworkOpts, function (err,body) {
    return err
      ? callback(err)
      : callback(null, new self.models.Network(self, body.network));
  });
};

/**
 * client.destroyNetwork
 *
 * @description Delete a specific network
 *
 * @param {String|object}     network     the network or network ID
 * @param callback
 */
exports.destroyNetwork = function (network, callback) {
  var networkId = network instanceof this.models.Network ? network.id : network,
    self = this;
  self.emit('log::trace', 'Deleting network', networkId);
  this._request({
    path: urlJoin('/v2.0/networks',networkId),
    method: 'DELETE'
  }, function (err, body, res) {
    if (err) {
      return callback(err);
    }
    callback(null, networkId);
  });
};

/**
 * _convertNetworkToWireFormat
 *
 * @description convert Network instance into its wire representation.
 *
 * @param {object}     details    the Network instance.
 */
_convertNetworkToWireFormat = function (details){
  var wireFormat = {};
  wireFormat.admin_state_up = details.admin_state_up || details.adminStateUp;
  wireFormat.name = details.name;
  wireFormat.shared = details.shared;
  wireFormat.tenant_id = details.tenantId || details.tenant_id;
  return wireFormat;
};
