/*
 * server.js: OpenStack Cloud server
 *
 * (C) 2013 Nodejitsu Inc.
 *
 */

var utile   = require('utile'),
    compute = require('../../core/compute'),
    base    = require('../../core/compute/server'),
    _       = require('underscore');

var Server = exports.Server = function Server(client, details) {
  base.Server.call(this, client, details);
};

utile.inherits(Server, base.Server);

Server.prototype._setProperties = function (details) {
  var self = this;
  // Set core properties
  this.id   = details.id;
  this.name = details.name;

  if (details.status) {
    switch (details.status.toUpperCase()) {
      case 'BUILD':
      case 'REBUILD':
        this.status = this.STATUS.provisioning;
        break;
      case 'ACTIVE':
        this.status = this.STATUS.running;
        break;
      case 'SUSPENDED':
      case 'SHUTOFF':
        this.status = this.STATUS.stopped;
        break;
      case 'REBOOT':
      case 'HARD_REBOOT':
        this.status = this.STATUS.reboot;
        break;
      case 'QUEUE_RESIZE':
      case 'PREP_RESIZE':
      case 'RESIZE':
      case 'VERIFY_RESIZE':
      case 'SHARE_IP':
      case 'SHARE_IP_NO_CONFIG':
      case 'DELETE_IP':
      case 'PASSWORD':
        this.status = this.STATUS.updating;
        break;
      case 'RESCUE':
      case 'ERROR':
        this.status = this.STATUS.error;
        break;
      default:
        this.status = this.STATUS.unknown;
        break;
    }
  }

  //
  // Set extra properties
  //
  this.progress  = details.progress;
  this.imageId   = details.imageId   || this.imageId;
  this.adminPass = details.adminPass || this.adminPass;
  this.addresses = details.addresses || {};
  this.metadata  = details.metadata  || {};
  this.flavorId  = details.flavorId  || this.flavorId;
  this.hostId    = details.hostId    || this.hostId;
  this.created   = details.created   || this.created;
  this.updated   = details.updated   || this.updated;
  this.original  = this.openstack = details;

  if (Object.keys(this.addresses).length && !this.addresses.public
    && !this.addresses.private) {
    this.addresses = Object.keys(this.addresses)
      .map(function (network) {
        return self.addresses[network];
      })
      .reduce(function (all, interfaces) {
        Object.keys(interfaces).map(function (interface) {
          return interfaces[interface].addr;
        })
        .forEach(function (addr) {
          return compute.isPrivate(addr)
            ? all['private'].push(addr)
            : all['public'].push(addr);
        });

        return all;
      }, { public: [], private: [] });
  }

  // Try to set the flavorId using a flavor object
  if (typeof this.flavorId === "undefined" &&
      details.flavor && details.flavor.id) {
    this.flavorId = details.flavor.id;
  }

  // Try to set the imageId using an image object
  if (typeof this.imageId === "undefined" &&
      details.image && details.image.id) {
    this.imageId = details.image.id;
  }
};

//
// Updates the addresses for this instance
// Parameters: type['public' || 'private]? callback
//
Server.prototype.getAddresses = function (type, callback) {
  if (!callback && typeof type === 'function') {
    callback = type;
    type = '';
  }

  var self = this;
  this.client.getServerAddresses(this, type, function (err, addresses) {
    if (err) {
      return callback(err);
    }

    if (type === '') {
      self.addresses = addresses;
    }
    else {
      self.addresses = addresses || {};
      self.addresses[type] = addresses[type];
    }

    callback(null, addresses);
  });
};

Server.prototype.toJSON = function() {
  return _.pick(this, ['id', 'name', 'status', 'hostId', 'addresses',
    'links', 'key_name', 'image', 'flavor', 'user_id', 'tenant_id', 'progress',
    'OS-EXT-STS:task_state', 'OS-EXT-STS:vm_state', 'OS-EXT-STS:power_state',
    'OS-DCF:diskConfig', 'accessIPv4', 'accessIPv6', 'config_drive', 'metadata',
    'created', 'updated']);
};