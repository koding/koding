/*
 * flavor.js: Azure Cloud Package flavors
 *
 * (C) Microsoft Open Technologies, Inc.
 *
 */

var utile = require('utile'),
    base  = require('../../core/compute/flavor');

var Flavor = exports.Flavor = function Flavor(client, details) {
  base.Flavor.call(this, client, details);
};

utile.inherits(Flavor, base.Flavor);

Flavor.options = {
  'ExtraSmall': { ram: 0.768 * 1024, disk: 20 },
  'Small': { ram: 1.75 * 1024, disk: 50 },
  'Medium': { ram: 3.5 * 1024, disk: 100 },
  'Large': { ram: 7 * 1024, disk: 200 },
  'ExtraLarge': { ram: 14 * 1024, disk: 400 }
};

Flavor.prototype._setProperties = function (details) {
  var id = details.name || details.id || 'ExtraSmall';

  if (!Flavor.options[id]) throw new TypeError('No such Azure Flavor: ' + id);

  this.id   = id;
  this.name = id;
  this.ram  = Flavor.options[id].ram;
  this.disk = Flavor.options[id].disk;
};
