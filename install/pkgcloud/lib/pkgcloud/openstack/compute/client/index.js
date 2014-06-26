/*
 * index.js: Compute client for OpenStack
 *
 * (C) 2013 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    openstack = require('../../client'),
    ComputeClient = require('../computeClient').ComputeClient,
    _ = require('underscore');

var Client = exports.Client = function (options) {
  openstack.Client.call(this, options);

  utile.mixin(this, require('./flavors'));
  utile.mixin(this, require('./images'));
  utile.mixin(this, require('./servers'));
  utile.mixin(this, require('./extensions'));

  this.serviceType = 'compute';
};

utile.inherits(Client, openstack.Client);
_.extend(Client.prototype, ComputeClient.prototype);
