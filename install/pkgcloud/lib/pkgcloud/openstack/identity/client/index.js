/*
 * index.js: Identity client for Openstack
 *
 * (C) 2014 Rackspace, Ken Perkins
 * MIT LICENSE
 *
 */

var utile = require('utile'),
    urlJoin = require('url-join'),
    openstack = require('../../client'),
    _ = require('underscore');

var Client = exports.Client = function (options) {
  openstack.Client.call(this, options);

  this.serviceType = null;
};

utile.inherits(Client, openstack.Client);

/**
 * Client._getUrl
 *
 * @description a helper function for determining the ultimate URL for this service
 * @param options
 * @returns {exports|*}
 * @private
 */
Client.prototype._getUrl = function (options) {
  options = options || {};

  return urlJoin(this._serviceUrl,
    typeof options === 'string'
      ? options
      : options.path);

};

/**
 * Client.validateToken
 *
 * This is an administrative API that allows a admin user to validate the token of
 * another authenticated user.
 *
 * @param {String}  token   the token to validate
 * @param {String|Function}  [belongsTo]  The tenantId of the user to match with the token
 * @param callback
 */
Client.prototype.validateToken = function (token, belongsTo, callback) {
  if (!token || typeof token === 'function') {
    throw new Error('Token is a required argument');
  }

  if (typeof belongsTo === 'function' && !callback) {
    callback = belongsTo;
    belongsTo = null;
  }

  var options = {
    path: urlJoin('/v2.0/tokens', token)
  };

  if (belongsTo) {
    options.qs = {
      belongsTo: belongsTo
    };
  }

  this._request(options, function (err, body, res) {
    return err
      ? callback(err)
      : callback(err, body);
  });
};

/**
 *  Client.getTenantInfo
 *
 *  This is an administrative API that allows a admin to get detailed information about the specified tenant by ID
 *
 *  @param {String|Function}  [tenantId]  The tenantId for which we are seeking info
 *  @param callback
 *
 */
Client.prototype.getTenantInfo = function (tenantId, callback) {

  if (typeof tenantId === 'function' && !callback) {
    callback = tenantId;
    tenantId = null;
  }

  var options = {
    path: urlJoin('/v2.0/tenants', tenantId ? tenantId : '')
  };

  this._request(options, function (err, body, res) {
    return err
      ? callback(err)
      : callback(err, body);
  });

};