/*
 * flavor.js: OpenStack Cloud flavor
 *
 * (C) 2013 Nodejitsu Inc.
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
  this.ram  = details.ram;
  this.disk = details.disk;
  this.vcpus = details.vcpus;
  this.swap = details.swap;
};
