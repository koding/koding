/*
 * index.js: Compute client for Joyent CloudAPI
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var utile     = require('utile'),
    urlJoin   = require('url-join'),
    joyent    = require('../../client');

var Client = exports.Client = function (options) {
  joyent.Client.call(this, options);

  utile.mixin(this, require('./flavors'));
  utile.mixin(this, require('./images'));
  utile.mixin(this, require('./servers'));
  utile.mixin(this, require('./keys'));
};

utile.inherits(Client, joyent.Client);

Client.prototype._getUrl = function (options) {
  options = options || {};

  var root = this.serversUrl
    ? this.protocol + this.serversUrl
    : this.protocol + 'us-sw-1.api.joyentcloud.com';

  return urlJoin(root, typeof options === 'string'
    ? options
    : options.path);
};
