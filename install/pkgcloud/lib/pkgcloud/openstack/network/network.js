/*
 * network.js: Openstack Network object.
 *
 * (C) 2014 Hewlett-Packard Development Company, L.P.
 *
 */

var utile = require('utile'),
    base = require('../../core/network/network'),
    _ = require('underscore');

var Network = exports.Network = function Network(client, details) {
  base.Network.call(this, client, details);
};

utile.inherits(Network, base.Network);

Network.prototype._setProperties = function (details) {
  this.name = details.name || this.name;
  this.status = details.status || this.status;
  this.adminStateUp = details.admin_state_up || this.adminStateUp;
  this.id = details.id || this.id;
  this.shared = details.shared || this.shared || 0;
  this.tenantId = details.tenant_id || this.tenantId;
  this.subnets = details.subnets || this.subnets;
};

Network.prototype.toJSON = function () {
  return _.pick(this, ['name', 'id', 'adminStateUp', 'status', 'shared',
  'tenantId', 'subnets']);
};
