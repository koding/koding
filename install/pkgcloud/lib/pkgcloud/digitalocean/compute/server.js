/*
 * server.js: DigitalOcean Server
 *
 * (C) 2013 Nodejitsu Inc.
 *
 */

var utile   = require('utile'),
    compute = require('../../core/compute'),
    base    = require('../../core/compute/server');

var Server = exports.Server = function Server(client, details) {
  base.Server.call(this, client, details);
};

utile.inherits(Server, base.Server);

Server.prototype._setProperties = function (details) {
  this.id        = details.id;
  this.name      = details.name;
  this.imageId   = details.image_id;
  this.flavorId  = details.size_id;
  this.addresses = {
    public: [details.ip_address],
    private: []
  };

  switch (details.status && details.status.toUpperCase()) {
    case 'ACTIVE':
      this.status = "RUNNING";
      break;
    case 'NEW':
    default:
      this.status = 'PROVISIONING';
  }

  //
  // DigitalOcean specific
  //
  this.region   = details.region_id;
  this.original = this.digitalocean = details;
};
