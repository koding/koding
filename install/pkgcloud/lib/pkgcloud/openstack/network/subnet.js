/*
 * network.js: Openstack Subnet object.
 *
 * (C) 2014 Hewlett-Packard Development Company, L.P.
 *
 */

var utile = require('utile'),
    base = require('../../core/network/subnet'),
    _ = require('underscore');

var Subnet = exports.Subnet = function Subnet(client, details) {
  base.Subnet.call(this, client, details);
};

utile.inherits(Subnet, base.Subnet);

Subnet.prototype._setProperties = function (details) {
  this.name = details.name || this.name;
  this.enableDhcp = details.enable_dhcp || this.enableDhcp;
  this.networkId = details.network_id || this.networkId;
  this.id = details.id || this.id;
  this.ipVersion = details.ip_version || this.ipVersion;
  this.tenantId = details.tenant_id || this.tenantId;
  this.gatewayIp = details.gateway_ip || this.gatewayIp;
  this.cidr = details.cidr || this.cidr;
  this.dnsNameServers = details.dns_nameservers || this.dnsNameServers;
  this.hostRoutes = details.host_routes  || this.hostRoutes;
  this.allocationPools = details.allocation_pools  || this.allocationPools;
};

Subnet.prototype.toJSON = function () {
  return _.pick(this, ['name', 'id', 'networkId', 'ipVersion',
  'tenantId', 'gatewayIp', 'dnsNameServers', 'allocationPools', 'hostRoutes']);
};
