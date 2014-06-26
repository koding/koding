/*
 * client.js: Base client from which all HP clients inherit from
 *
 * (C) 2014 Hewlett-Packard Development Company, L.P.
 *
 */

var utile = require('utile'),
    identity = require('./identity'),
    base = require('../openstack/client'),
    _ = require('underscore');

var Client = exports.Client = function (options) {
  options = options || {};

  if (!options.authUrl){
      throw new Error('authUrl is invalid');
  }

  options.identity = identity.Identity;

  if (typeof options.useServiceCatalog === 'undefined') {
    options.useServiceCatalog = true;
  }

  base.Client.call(this, options);

  this.provider = 'hp';
};

utile.inherits(Client, base.Client);

Client.prototype._getIdentityOptions = function() {
  return _.extend({
    apiKey: this.config.apiKey
  }, Client.super_.prototype._getIdentityOptions.call(this));
};
