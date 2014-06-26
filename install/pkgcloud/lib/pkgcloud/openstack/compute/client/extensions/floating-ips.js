/*
 * floating-ips.js: OpenStack Floating IP Extension
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var Server = require('../../server').Server,
    urlJoin = require('url-join');

var _extension = 'os-floating-ips';

/**
 * client.getFloatingIps
 *
 * @description Lists floating IP addresses associated with the tenant or account.
 *
 * @param {function}        callback
 * @returns {*}
 */
exports.getFloatingIps = function (callback) {
  return this._request({
    path: urlJoin(_extension)
  }, function (err, body) {
    return err
      ? callback(err)
      : callback(err, body.floating_ips);
  });
};

/**
 * client.allocateNewFloatingIp
 *
 * @description Allocates a new floating IP address to a tenant or account.
 *
 * @param {String|function}     [pool]      The optional pool of IPs to allocate from
 * @param {function}            callback
 * @returns {*}
 */
exports.allocateNewFloatingIp = function(pool, callback) {
  if (typeof pool === 'function') {
    callback = pool;
    pool = null;
  }

  var options = {
    path: _extension,
    method: 'POST',
    body: {}
  };

  if (pool) {
    options.body.pool = pool;
  }

  return this._request(options, function(err, body) {
    return err
      ? callback(err)
      : callback(err, body.floating_ip);
  });
};

/**
 * client.getFloatingIp
 *
 * @description Get the details of a specific floating IP.
 *
 * @param {String|Object}   floatingIp     The floatingIp ID or object to get the details for
 * @param {function}        callback
 * @returns {*}
 */
exports.getFloatingIp = function(floatingIp, callback) {
  var floatingIpId = (typeof floatingIp === 'object') ? floatingIp.id : floatingIp;

  return this._request({
    path: urlJoin(_extension, floatingIpId)
  }, function (err, body) {
    return err
      ? callback(err)
      : callback(err, body.floating_ip);
  });
};

/**
 * client.deallocateFloatingIp
 *
 * @description Deallocates the floating IP address by id
 *
 * @param {String|Object}   floatingIp     The floatingIp ID or object to deallocate
 * @param {function}        callback
 * @returns {*}
 */
exports.deallocateFloatingIp = function (floatingIp, callback) {

  var floatingIpId = (typeof floatingIp === 'object') ? floatingIp.id : floatingIp;

  return this._request({
    path: urlJoin(_extension, floatingIpId),
    method: 'DELETE'
  }, function (err) {
    return callback(err);
  });
};

/**
 * client.addFloatingIp
 *
 * @description Add a floating IP to a specific server instance
 *
 * @param {String|Object}   server          The server ID or server to add the floating IP to
 * @param {String|Object}   floatingIp      The floatingIp address or object
 * @param {function}        callback
 * @returns {*}
 */
exports.addFloatingIp = function (server, floatingIp, callback) {
  var floatingIpAddress = (typeof floatingIp === 'object') ? floatingIp.ip : floatingIp

  return this._doServerAction(server, {
    addFloatingIp: {
      address: floatingIpAddress
    }
  }, function (err) {
    return callback(err);
  });
};

/**
 * client.removeFloatingIp
 *
 * @description Remove a floating IP from a specific server instance
 *
 * @param {String|Object}   server          The server ID or server to remove the floating IP from
 * @param {String|Object}   floatingIp      The floatingIp address or object
 * @param {function}        callback
 * @returns {*}
 */
exports.removeFloatingIp = function (server, floatingIp, callback) {
  var floatingIpAddress = (typeof floatingIp === 'object') ? floatingIp.ip : floatingIp

  return this._doServerAction(server, {
    removeFloatingIp: {
      address: floatingIpAddress
    }
  }, function (err) {
    return callback(err);
  });
};

