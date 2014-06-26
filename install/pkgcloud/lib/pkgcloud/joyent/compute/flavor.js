/*
 * flavor.js: Joyent Cloud Package
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
  this.id         = details.name;
  this.name       = details.name;
  this.ram        = details.memory;
  this.disk       = details.disk;

  //
  // Joyent specific
  //
  this.swap       = details.swap;
  this["default"] = details["default"];
  this.original   = this.joyent = details;
};