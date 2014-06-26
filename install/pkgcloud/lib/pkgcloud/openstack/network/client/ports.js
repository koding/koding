/*
 * ports.js: Instance methods for working with ports
 * for Openstack porting
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
 * client.getPorts
 *
 * @description get the list of ports for an account
 *
 * @param {object|Function}   options
 * @param {Function}          callback
 */
exports.getPorts  = function (options, callback) {
  var self = this;

  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  var getPortOpts = {
    path: '/v2.0/ports'
  };

  this._request(getPortOpts, function (err, body) {
    if (err) {
      return callback(err);
    }
    else if (!body || !body.ports || !(body.ports instanceof Array)) {
      return new Error('Malformed API Response');
    }

    return callback(null, body.ports.map(function (port) {
      return new self.models.Port(self, port);
    }));
  });
};

/**
 * client.getPort
 *
 * @description get the details for a specific port
 *
 * @param {String|object}     port     the port or portId
 * @param callback
 */
exports.getPort = function (port, callback) {
  var portId = port instanceof this.models.Port ? port.id : port,
    self = this;
  self.emit('log::trace', 'Getting details for port', portId);
  this._request({
    path: urlJoin('/v2.0/ports', portId),
    method: 'GET'
  }, function (err, body, res) {
    if (err) {
      return callback(err);
    }

    if (!body ||!body.port) {
      return new Error('Malformed API Response');
    }

    callback(null, new self.models.Port(self, body.port));
  });
};

/**
 * client.createPort
 *
 * @description create a new port
 *
 * @param {object}    options
 * @param {String}    options.name      the name of the new port
 * @param callback
 */
exports.createPort = function (options, callback) {
  var port = typeof options === 'object' ? options : { 'name' : options},
      self = this;

  port = _convertPortToWireFormat(port);

  var createPortOpts = {
    method: 'POST',
    path: '/v2.0/ports',
    body: { 'port' : port}
  };

  self.emit('log::trace', 'Creating port', port);
  this._request(createPortOpts, function (err,body) {
    return err
      ? callback(err)
      : callback(null, new self.models.Port(self, body.port));
  });
};

/**
 * client.updatePort
 *
 * @description update an existing port
 *
 * @param {object}    options
 * @param callback
 */
exports.updatePort = function (port, callback) {
  var self = this,
  portId = port.id;

  port = _convertPortToWireFormat(port);
  var updatePortOpts = {
    method: 'PUT',
    path: urlJoin('/v2.0/ports', portId),
    contentType: 'application/json',
    body: { 'port' : port}
  };

  self.emit('log::trace', 'Updating port', port);
  this._request(updatePortOpts, function (err,body) {
    return err
      ? callback(err)
      : callback(null, new self.models.Port(self, body.port));
  });
};

/**
 * client.destroyPort
 *
 * @description Delete a specific port
 *
 * @param {String|object}     port     the port or port ID
 * @param callback
 */
exports.destroyPort = function (port, callback) {
  var portId = port instanceof this.models.Port ? port.id : port,
    self = this;
  self.emit('log::trace', 'Deleting port', portId);
  this._request({
    path: urlJoin('/v2.0/ports',portId),
    method: 'DELETE'
  }, function (err, body, res) {
    if (err) {
      return callback(err);
    }
    callback(null, portId);
  });
};

/**
 * _convertPortToWireFormat
 *
 * @description convert Port instance into its wire representation.
 *
 * @param {object}     details    the Port instance.
 */
_convertPortToWireFormat = function (details){
    var wireFormat = {};
    wireFormat.status = details.status;
    wireFormat.name = details.name;
    wireFormat.admin_state_up = details.admin_state_up || details.adminStateUp;
    wireFormat.tenant_id = details.tenant_id || details.tenantId;
    wireFormat.mac_address = details.mac_address || details.macAddress;
    wireFormat.fixed_ips = details.fixed_ips || details.fixedIps;
    wireFormat.security_groups  = details.security_groups  || details.securityGroups;
    wireFormat.network_id = details.network_id || details.networkId;
    return wireFormat;
};
