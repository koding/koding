/*
 * network.js: Openstack Port object.
 *
 * (C) 2014 Hewlett-Packard Development Company, L.P.
 *
 */

var utile = require('utile'),
    base = require('../../core/network/port'),
    _ = require('underscore');

var Port = exports.Port = function Port(client, details) {
  base.Port.call(this, client, details);
};

utile.inherits(Port, base.Port);

Port.prototype._setProperties = function (details) {

  this.status = details.status || this.status;
  this.name = details.name || this.name;
  this.allowedAddressPairs = details.allowed_address_pairs	 || this.allowedAddressPairs;
  this.adminStateUp = details.admin_state_up || this.adminStateUp;
  this.networkId = details.network_id || this.networkId;
  this.tenantId = details.tenant_id || this.tenantId;
  this.extraDhcpOpts = details.extra_dhcp_opts || this.extraDhcpOpts;
  this.deviceOwner = details.device_owner || this.deviceOwner;
  this.macAddress = details.mac_address || this.macAddress;
  this.fixedIps = details.fixed_ips || this.fixedIps;
  this.id = details.id || this.id;
  this.securityGroups = details.security_groups || this.securityGroups;
  this.deviceId = details.device_id || this.deviceId;
};

Port.prototype.toJSON = function () {
  return _.pick(this, ['status', 'name', 'allowedAddressPairs', 'adminStateUp',
  'networkId', 'tenantId', 'extraDhcpOpts', 'deviceOwner',
  'macAddress', 'fixedIps', 'id', 'securityGroups', 'deviceId']);
};
