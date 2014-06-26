/*
 * index.js: Compute client for DigitalOcean API
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var utile        = require('utile'),
    urlJoin      = require('url-join'),
    digitalocean = require('../../client');

var Client = exports.Client = function (options) {
  digitalocean.Client.call(this, options);

  utile.mixin(this, require('./flavors'));
  utile.mixin(this, require('./images'));
  utile.mixin(this, require('./servers'));
  utile.mixin(this, require('./keys'));
};

utile.inherits(Client, digitalocean.Client);

Client.prototype._getUrl = function (options) {
  options = options || {};

  var root = this.serversUrl
    ? this.protocol + this.serversUrl
    : this.protocol + 'api.digitalocean.com';

  return urlJoin(root, typeof options === 'string'
    ? options
    : options.path);
};
