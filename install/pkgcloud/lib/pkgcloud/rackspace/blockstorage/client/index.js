/*
 * index.js: Cloud BlockStorage client for Rackspace
 *
 * (C) 2013 Rackspace
 *      Ken Perkins
 * MIT LICENSE
 *
 */

var utile = require('utile'),
    urlJoin = require('url-join'),
    rackspace = require('../../client');

var Client = exports.Client = function (options) {
  rackspace.Client.call(this, options);

  utile.mixin(this, require('./volumetypes'));
  utile.mixin(this, require('./snapshots'));
  utile.mixin(this, require('./volumes'));

  this.serviceType = 'volume';
};

utile.inherits(Client, rackspace.Client);

Client.prototype._getUrl = function (options) {
  options = options || {};

  return urlJoin(this._serviceUrl,
    typeof options === 'string'
      ? options
      : options.path);

};
