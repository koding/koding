/*
 * server.js: AWS Server
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    base  = require('../../core/compute/server');

var Server = exports.Server = function Server(client, details) {
  base.Server.call(this, client, details);
};

utile.inherits(Server, base.Server);

Server.prototype._setProperties = function (details) {
  this.id   = details.instanceId;
  this.name = details.name || (details.meta || {}).name;

  if (details.instanceState) {
    switch (details.instanceState.name.toUpperCase()) {
      case 'PENDING':
        this.status = this.STATUS.provisioning;
        break;
      case 'RUNNING':
        this.status = this.STATUS.running;
        break;
      case 'STOPPING':
      case 'STOPPED':
        this.status = this.STATUS.stopped;
        break;
      case 'TERMINATED':
        this.status = this.STATUS.terminated;
        break;
      default:
        this.status = this.STATUS.unknown;
        break;
    }
  }

  var addresses = { private: [], public: [] };

  ['ipAddress', 'dnsName'].forEach(function (prop) {
    if (typeof details[prop] === 'string') {
      addresses.public.push(details[prop]);
    }
  });

  ['privateIpAddress', 'privateDnsName'].forEach(function (prop) {
    if (typeof details[prop] === 'string') {
      addresses.private.push(details[prop]);
    }
  });

  //
  // AWS specific
  //
  this.imageId    = details.imageId;
  this.addresses  = details.addresses = addresses;
  this.launchTime = details.launchTime;
  this.type       = details.instanceType;
  this.original   = this.amazon = details;
};
