/*
 * client.js: Client for Openstack networking
 *
 * (C) 2014 Hewlett-Packard Development Company, L.P.
 *
 */

var utile = require('utile'),
    urlJoin = require('url-join'),
    openstack = require('../../client'),
    NetworkClient = require('../networkClient').NetworkClient,
    _ = require('underscore');

var Client = exports.Client = function (options) {
  openstack.Client.call(this, options);

  this.models = {
    Network: require('../network').Network,
    Subnet: require('../subnet').Subnet,
    Port: require('../port').Port
  };

  utile.mixin(this, require('./networks'));
  utile.mixin(this, require('./subnets'));
  utile.mixin(this, require('./ports'));

  this.serviceType = 'network';
};

utile.inherits(Client, openstack.Client);
_.extend(Client.prototype, NetworkClient.prototype);
