/*
 * flavor.js: DigitalOcean Server "Size"
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var utile = require('utile'),
    base  = require('../../core/compute/flavor');

var Flavor = exports.Flavor = function Flavor(client, details) {
  base.Flavor.call(this, client, details);
};

utile.inherits(Flavor, base.Flavor);

Flavor.prototype._setProperties = function (details) {
  this.id   = details.id;
  this.name = details.name;
  this.ram  = details.memory;
  this.disk = details.disk;
  
  //
  // DigitalOcean specific
  //
  this.cpu          = details.cpu;
  this.costPerHour  = details.cost_per_hour;
  this.costPerMonth = details.cost_per_month;
  this.original     = this.digitalocean = details;
};