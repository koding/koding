/*
 * client.js: Compute client for HP Cloudservers
 *
 * (C) 2014 Hewlett-Packard Development Company, L.P.
 * Phani Raj
 *
 */

var utile = require('utile'),
    hp = require('../../client'),
    ComputeClient = require('../../../openstack/compute/computeClient').ComputeClient,
    _ = require('underscore');

var Client = exports.Client = function (options) {
  hp.Client.call(this, options);
  utile.mixin(this, require('../../../openstack/compute/client/flavors'));
  utile.mixin(this, require('../../../openstack/compute/client/images'));
  utile.mixin(this, require('../../../openstack/compute/client/servers'));
  utile.mixin(this, require('../../../openstack/compute/client/extensions/floating-ips'));
  utile.mixin(this, require('../../../openstack/compute/client/extensions/security-groups'));
  utile.mixin(this, require('../../../openstack/compute/client/extensions/servers'));

  this.serviceType = 'compute';
};

utile.inherits(Client, hp.Client);
_.extend(Client.prototype, ComputeClient.prototype);
