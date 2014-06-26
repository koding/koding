/*
 * computeClient.js: A base ComputeClient for Openstack &
 * Rackspace compute clients
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var urlJoin = require('url-join');

var Client = exports.ComputeClient = function () {
  this.serviceType = 'compute';
};

/**
 * client._getUrl
 *
 * @description get the url for the current compute service
 * 
 * @param options
 * @returns {exports|*}
 * @private
 */
Client.prototype._getUrl = function (options) {
  options = options || {};

  if (!this._serviceUrl) {
    throw new Error('Service url not found');
  }

  return urlJoin(this._serviceUrl,
    typeof options === 'string'
      ? options
      : options.path);
};

/**
 * client.getVersion
 *
 * @description get the version of the current openstack compute API
 * @param callback
 */
Client.prototype.getVersion = function getVersion(callback) {
  var self = this,
    verbose;

  this.auth(function (err) {
    if (err) {
      return callback(err);
    }

    self._request({
      uri: self._getUrl('/').replace(self._identity.token.tenant.id + '/', '')
    }, function (err, body) {
      if (err) {
        return callback(err);
      }
      verbose = ((typeof body === 'object') ? body.version : JSON.parse(body).version);
      return callback(null, verbose.id, verbose);
    });
  });
};

/**
 * client.getLimits
 *
 * @description Get the API limits for the current account
 * @param callback
 * @returns {*}
 */
Client.prototype.getLimits = function (callback) {
  return this._request({
    path: 'limits'
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, body.limits, res);
  });
};

