/*
 * client.js: Client for HP networking
 *
 * (C) 2014 Hewlett-Packard Development Company, L.P.
 *
 */

var utile = require('utile'),
    urlJoin = require('url-join'),
    hp = require('../../client'),
    NetworkClient = require('../../../openstack/network/networkClient').NetworkClient,
    _ = require('underscore');

var Client = exports.Client = function (options) {
  hp.Client.call(this, options);

  this.models = {
    Network: require('../../../openstack/network/network').Network,
    Subnet: require('../../../openstack/network/subnet').Subnet,
    Port: require('../../../openstack/network/port').Port
  };

  utile.mixin(this, require('../../../openstack/network/client/networks'));
  utile.mixin(this, require('../../../openstack/network/client/subnets'));
  utile.mixin(this, require('../../../openstack/network/client/ports'));

  this.serviceType = 'network';
};

utile.inherits(Client, hp.Client);
_.extend(Client.prototype, NetworkClient.prototype);
