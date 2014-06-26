/*
 * client.js: Database client for Rackspace Cloud Databases
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var utile     = require('utile'),
    urlJoin   = require('url-join'),
    request   = require('request'),
    rackspace = require('../../client'),
    auth      = require('../../../common/auth.js'),
    _         = require('underscore');

var Client = exports.Client = function (options) {
  rackspace.Client.call(this, options);

  this.before.push(auth.accountId);

  utile.mixin(this, require('./flavors'));
  utile.mixin(this, require('./instances'));
  utile.mixin(this, require('./databases'));
  utile.mixin(this, require('./users'));

  this.serviceType = 'rax:database';
};

utile.inherits(Client, rackspace.Client);

Client.prototype._getUrl = function (options) {
  options = options || {};

  return urlJoin(this._serviceUrl,
    typeof options === 'string'
      ? options
      : options.path);

};

//
// Gets the version of the OpenStack Compute API we are running against
// Parameters: callback
//
Client.prototype.getVersion = function getVersion(callback) {
  var self = this;

  this.auth(function (err) {
    if (err) {
      return callback(err);
    }

    self._request({
      uri: self._getUrl('/').replace('/v1.0/' + self._identity.token.tenant.id + '/', '')
    }, function (err, body) {
      if (err) {
        return callback(err);
      }
      return callback(null,
        ((typeof body === 'object') ? body.versions : JSON.parse(body).versions));
    });
  });
};
