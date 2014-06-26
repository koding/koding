/*
 * client.js: Base client from which all Rackspace clients inherit from
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    identity = require('./identity'),
    base = require('../openstack/client'),
    _ = require('underscore');

var Client = exports.Client = function (options) {
  options = options || {};
  options.authUrl = options.authUrl || 'https://identity.api.rackspacecloud.com';

  options.identity = identity.Identity;

  if (typeof options.useServiceCatalog === 'undefined') {
    options.useServiceCatalog = true;
  }

  base.Client.call(this, options);

  this.provider = 'rackspace';
};

utile.inherits(Client, base.Client);

Client.prototype._getIdentityOptions = function() {
  return _.extend({
    apiKey: this.config.apiKey
  }, Client.super_.prototype._getIdentityOptions.call(this));
};

