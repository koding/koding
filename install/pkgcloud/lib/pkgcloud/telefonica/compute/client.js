/*
 * index.js: Compute client for Telefonica InstantServers CloudAPI
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var utile     = require('utile'),
    urlJoin   = require('url-join'),
    joyent    = require('../../joyent/compute');

var Client = exports.Client = function (options) {
  joyent.Client.call(this, options);

  this.serversUrl = options.serversUrl
    || process.env.SDC_CLI_URL
    || 'api-eu-lon-1.instantservers.telefonica.com';
};

utile.inherits(Client, joyent.Client);

Client.prototype._getUrl = function (options) {
  options = options || {};

  return urlJoin(this.serversUrl
      ? 'https://' + this.serversUrl
      : 'https://api-eu-lon-1.instantservers.telefonica.com',
    (typeof options === 'string' ?
    options : options.path));
};
